#!/bin/bash
#
# update-golang is a script to easily fetch and install new Golang releases
#
# Home: https://github.com/udhos/update-golang
#
# PIPETHIS_AUTHOR udhos

version=0.12

set -o pipefail

me=$(basename "$0")
msg() {
    echo >&2 "$me": "$*"
}

debug() {
    [ -n "$DEBUG" ] && msg debug: "$*"
}

log_stdin() {
    while read -r i; do
	msg "$i"
    done
}

# defaults
source=https://storage.googleapis.com/golang
destination=/usr/local
release=1.9.2
profiled=/etc/profile.d/golang_path.sh
arch_probe="uname -m"

os=$(uname -s | tr "[:upper:]" "[:lower:]")

[ -n "$ARCH_PROBE" ] && arch_probe="$ARCH_PROBE"

arch=$($arch_probe)
case "$arch" in
    i*)
	arch=386
	;;
    x*)
        arch=amd64
	;;
    aarch64)
        arch=armv6l
	;;
    armv7l)
        arch=armv6l
	;;
esac

[ -n "$SOURCE" ] && source=$SOURCE
[ -n "$DESTINATION" ] && destination=$DESTINATION
[ -n "$RELEASE" ] && release=$RELEASE
[ -n "$OS" ] && os=$OS
[ -n "$ARCH" ] && arch=$ARCH
[ -n "$PROFILED" ] && profiled=$PROFILED
cache=$destination
[ -n "$CACHE" ] && cache=$CACHE

show_vars() {
    echo user: "$(id)"
    
    cat <<EOF
SOURCE=$source
DESTINATION=$destination
RELEASE=$release
OS=$os
ARCH_PROBE=$arch_probe
ARCH=$arch
PROFILED=$profiled
CACHE=$cache
GOPATH=$GOPATH
DEBUG=$DEBUG
EOF
}

label=go$release.$os-$arch
filename=$label.tar.gz
url=$source/$filename
goroot=$destination/go
filepath=$cache/$filename
new_install=$destination/$label

tmp= ;# will be set
save_dir=$PWD
previous_install= ;# will be set
cleanup() {
    [ -n "$tmp" ] && [ -f "$tmp" ] && msg cleanup: $tmp && rm $tmp
    [ -n "$save_dir" ] && cd "$save_dir" || exit 2
    [ -n "$previous_install" ] && msg remember to delete previous install saved as: "$previous_install"
}

die() {
    msg "die: $*"
    cleanup
    exit 3
}

solve() {
    local path=$1
    local p=
    if echo "$path" | grep -E -q ^/; then
	p="$path"
	local m=
	m=$(file "$p")
        debug "solve: $p: $m"
    else
	p="$save_dir/$path"
    fi
    echo "$p"
}

abs_filepath=$(solve "$filepath")
abs_url=$(solve "$url")
abs_goroot=$(solve "$goroot")
abs_new_install=$(solve "$new_install")
abs_gobin=$abs_goroot/bin
abs_gotool=$abs_gobin/go
abs_profiled=$(solve "$profiled")

download() {
    if echo "$url" | grep -E -q '^https?:'; then
	msg "$url" is remote
	if [ -f "$abs_filepath" ]; then
            msg no need to download - file cached: "$abs_filepath"
	else
	    if hash wget 2>/dev/null; then
              wget -O "$abs_filepath" "$url" || die could not download using wget from: "$url"
	      [ -f "$abs_filepath" ] || die missing file downloaded with wget: "$abs_filepath"
            else
              curl -o "$abs_filepath" "$url" || die could not download using curl from: "$url"
	      [ -f "$abs_filepath" ] || die missing file downloaded with curl: "$abs_filepath"
            fi
	fi
    else
	msg "$abs_url" is local
	cp "$abs_url" . || die could not copy from: "$abs_url"
    fi
}

symlink_test() {
    #file "$1" | grep -q symbolic
    readlink "$1" >/dev/null
}

symlink_get() {
    #local f=
    #local j=
    #f=$(file "$1")
    #j=$(echo "$f" | awk '{print $NF}')
    #debug "symlink_get: $1: [$f]: [$j]"
    #echo "$j"
    readlink "$1"
}

remove_old_link() {
    if symlink_test "$abs_goroot"; then
        abs_old_install=$(symlink_get "$abs_goroot")
        msg remove_old_link: found symlink for old install: "$abs_old_install"
    	[ -r "$abs_goroot" ] && rm "$abs_goroot"
    else
        msg remove_old_link: not found symlink for old install
    	if [ -r "$abs_goroot" ]; then
		local now
		now=$(date +%Y%m%d-%H%M%S)
		mv "$abs_goroot" "$abs_goroot-$now" || die could not rename existing goland directory: "$abs_goroot"
		previous_install="$abs_goroot-$now"
		msg previous install renamed to: "$previous_install"
	fi
    fi
    [ -r "$abs_goroot" ] && die could not remove existing golang directory: "$abs_goroot"
}

rm_dir() {
    local dir=$1
    rm -r "$dir"
}

untar() {
    if [ -d "$abs_new_install" ]; then
        msg untar: rm_dir "$abs_new_install"
        rm_dir "$abs_new_install" || die untar: could not remove: "$abs_new_install"
    fi
    [ -d "$PWD" ] || die untar: not a directory: "$PWD"
    [ -w "$PWD" ] || die untar: unable to write: "$PWD"
    local cmd="tar -x -f $abs_filepath"
    msg untar: "$cmd"
    $cmd || die untar: failed: "$abs_filepath"
}

relink() {
    mv "$abs_goroot" "$abs_new_install"
    ln -s "$abs_new_install" "$abs_goroot"
}

path_mark=update-golang.sh

path_remove() {
    if [ -f "$abs_profiled" ]; then
        msg path: removing old settings from: "$abs_profiled"
        tmp=$(mktemp -t) # save for later removal
        if [ ! -f "$tmp" ]; then
            msg path: could not create temporary file: "$tmp"
            return
        fi
        grep -v "$path_mark" "$abs_profiled" > "$tmp"
        cp "$tmp" "$abs_profiled"
    fi
}

default_goroot=/usr/local/go

path() {
    path_remove

    msg path: issuing new "$abs_gobin" to "$abs_profiled"
    local dont_edit=";# DOT NOT EDIT: installed by $path_mark"
    echo "export PATH=\$PATH:$abs_gobin $dont_edit" >> "$abs_profiled"

    local user_gobin=
    [ -n "$GOPATH" ] && user_gobin=$(echo "$GOPATH" | awk -F: '{print $1}')/bin
    [ -z "$user_gobin" ] && user_gobin=$HOME/go/bin
    msg path: issuing "$user_gobin" to "$abs_profiled"
    echo "export PATH=\$PATH:$user_gobin $dont_edit" >> "$abs_profiled"

    if [ "$abs_goroot" != $default_goroot ]; then
        msg path: setting up custom GOROOT="$abs_goroot" to "$abs_profiled"
        echo "export GOROOT=$abs_goroot $dont_edit" >> "$abs_profiled"
    fi
}

test() {
    local ret=1
    local t="$abs_gotool version"
    if [ "$abs_goroot" != $default_goroot ]; then
        msg testing: GOROOT="$abs_goroot" "$t"
        GOROOT=$abs_goroot $t | log_stdin
        ret=$?
    else
        msg testing: "$t"
        $t | log_stdin
        ret=$?
    fi
    if [ $ret -eq 0 ]; then
        msg "$t": SUCCESS
    else
        msg "$t" FAIL
    fi

    local hello=
    hello=$(mktemp -t hello-tmpXXXXXXXX.go)
    cat >"$hello" <<__EOF__
package main

import "fmt"

func main() {
	fmt.Printf("hello, world\n")
}
__EOF__

    local abs_hello=
    abs_hello=$(solve "$hello")
    ret=1
    t="$abs_gotool run $abs_hello"
    if [ "$abs_goroot" != $default_goroot ]; then
        msg testing: GOROOT="$abs_goroot" "$t"
        GOROOT=$abs_goroot $t | log_stdin
        ret=$?
    else
        msg testing: "$t"
        $t | log_stdin
        ret=$?
    fi
    if [ $ret -eq 0 ]; then
        msg "$t": SUCCESS
    else
        msg "$t" FAIL
    fi

    rm "$hello"
}

remove_golang() {
    if symlink_test "$abs_goroot"; then
        local old_install=
        old_install=$(symlink_get "$abs_goroot")
        msg remove: found symlink for old install: "$old_install"
        msg remove: removing symlink: "$abs_goroot"
        rm "$abs_goroot"
        msg remove: removing dir: "$old_install"
        rm_dir "$old_install"
    else
        msg remove: not found symlink for old install
    fi

    path_remove
}

remove_old_install() {
    if [ -n "$abs_old_install" ]; then
	if [ "$abs_old_install" != "$abs_new_install" ]; then
            # remove old install only if it actually changed
            msg removing old install: "$abs_old_install"
            rm_dir "$abs_old_install"
	fi
    fi
}

show_version() {
    msg version $version
}

# update pre-commit hook
[ -d .git ] && [ ! -h .git/hooks/pre-commit ] && ln -s ../../pre-commit .git/hooks/pre-commit

#
# main section: begin
#

[ -d "$abs_profiled" ] && die "PROFILED=$profiled cannot be a directory"

case "$1" in
    -v)
	show_version
	exit 0
	;;
    remove)
	remove_golang
	exit 0
	;;
    '')
	;;
    *)
	msg unknown option: "$1"
	echo >&2 usage: "$me [-v] [remove]"
	exit 1
	;;
esac

show_version

show_vars | log_stdin

msg will install golang "$label" as: "$abs_goroot"

cd "$destination" || die could not enter destination="$destination"

download
remove_old_link
untar
relink
remove_old_install
path

msg golang "$label" installed at: "$abs_goroot"

test
cleanup

exit 0

#
# main section: end
#
