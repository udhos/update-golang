#!/usr/bin/env bash
#
# update-golang is a script to easily fetch and install new Golang releases
#
# Home: https://github.com/udhos/update-golang
#
# PIPETHIS_AUTHOR udhos

# ignore runtime environment variables
# shellcheck disable=SC2153
version=0.24

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
#release_list=https://golang.org/doc/devel/release.html
release_list=https://golang.org/dl/
source=https://storage.googleapis.com/golang
destination=/usr/local
release=1.16.4 ;# just the default. the script detects the latest available release.
arch_probe="uname -m"

os=$(uname -s | tr "[:upper:]" "[:lower:]")

if [ -d /etc/profile.d ]; then
    profiled=/etc/profile.d/golang_path.sh
else
    profiled=/etc/profile
fi

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
        #arch=armv6l
        arch=arm64
        ;;
    armv7l)
        # Go project does not provide a binary release for armv71
        msg armv7l is not supported, using armv6l
        arch=armv6l
        ;;
esac

show_version() {
    msg version $version
}

show_version

# avoid trying 1.12beta because 1.12beta1 is valid while 1.12beta is not
# if you want beta, force RELEASE=1.12beta1
exclude_beta() {
	grep -v -E 'go[0-9\.]+(beta|rc)'
}

scan_versions() {
    local fetch="$*"
    debug scan_versions: from "$release_list"
    if has_cmd jq; then
        local rl="$release_list?mode=json"
        msg "parsing with jq from $rl"
        $fetch "$rl" | jq -r '.[].files[].version' | sort | uniq | exclude_beta | sed -e 's/go//' | sort -V
    else
        $fetch "$release_list" | exclude_beta | grep -E -o 'go[0-9\.]+' | grep -E -o '[0-9]\.[0-9]+(\.[0-9]+)?' | sort -V | uniq
    fi
}

has_cmd() {
	#command -v "$1" >/dev/null
	hash "$1" 2>/dev/null
}

tmp='' ;# will be set
save_dir=$PWD
previous_install='' ;# will be set
declutter='' ;# will be set
tar_to_remove='' ;# will be set
cleanup() {
    [ -n "$tmp" ] && [ -f "$tmp" ] && msg cleanup: $tmp && rm $tmp
    [ -n "$declutter" ] && [ -n "$tar_to_remove" ] && [ -f "$tar_to_remove" ] && msg cleanup: $tar_to_remove && rm $tar_to_remove
    [ -n "$save_dir" ] && cd "$save_dir" || exit 2
    [ -n "$previous_install" ] && msg remember to delete previous install saved as: "$previous_install"
}

die() {
    msg "die: $*"
    cleanup
    exit 3
}

find_latest() {
    debug find_latest: built-in version: "$release"
    debug find_latest: from "$release_list"
    local last=
    local fetch=
    if has_cmd wget; then
	fetch="wget -qO-"
    elif has_cmd curl; then
	fetch="curl --silent"
    else
	die "find_latest: missing both 'wget' and 'curl'"
    fi
    last=$(scan_versions "$fetch" | tail -1)
    if echo "$last" | grep -q -E '[0-9]\.[0-9]+(\.[0-9]+)?'; then
	msg find_latest: found last release: "$last"
	release=$last
    fi
}

[ -n "$RELEASE_LIST" ] && release_list=$RELEASE_LIST

if [ -n "$RELEASE" ]; then
	msg release forced to RELEASE="$RELEASE"
	release="$RELEASE"
else
	find_latest
fi

[ -n "$SOURCE" ] && source=$SOURCE
[ -n "$DESTINATION" ] && destination=$DESTINATION
[ -n "$OS" ] && os=$OS
[ -n "$ARCH" ] && arch=$ARCH
cache=$destination
[ -n "$CACHE" ] && cache=$CACHE
[ -n "$PROFILED" ] && profiled=$PROFILED

show_vars() {
    echo user: "$(id)"

    cat <<EOF
RELEASE_LIST=$release_list
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
	    if has_cmd wget; then
              wget -O "$abs_filepath" "$url" || die could not download using wget from: "$url"
	      [ -f "$abs_filepath" ] || die missing file downloaded with wget: "$abs_filepath"
            elif has_cmd curl; then
              curl -o "$abs_filepath" "$url" || die could not download using curl from: "$url"
	      [ -f "$abs_filepath" ] || die missing file downloaded with curl: "$abs_filepath"
            else
              die "download: missing both 'wget' and 'curl'"
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
    tar_to_remove="$abs_filepath"
}

relink() {
    mv "$abs_goroot" "$abs_new_install"
    ln -s "$abs_new_install" "$abs_goroot"
}

path_mark=update-golang.sh

profile_path_remove() {
    if [ -f "$abs_profiled" ]; then
        msg profile_path_remove: removing old settings from: "$abs_profiled"
        tmp=$(mktemp -t profile-tmpXXXXXXXX) # save for later removal
        if [ ! -f "$tmp" ]; then
            msg profile_path_remove: could not create temporary file: "$tmp"
            return
        fi
        sed "/# DO NOT EDIT: installed by $path_mark/,/# $path_mark: end/d" "$abs_profiled" > "$tmp"
        cp "$tmp" "$abs_profiled"
    fi
}

default_goroot=/usr/local/go

profile_path_add() {
    profile_path_remove
    { echo "# DO NOT EDIT: installed by $path_mark"; echo ""; }  >> "$abs_profiled"

    msg profile_path_add: issuing new "$abs_gobin" to "$abs_profiled"
    { echo 'if ! echo "$PATH" | grep -Eq "(^|:)'"$abs_gobin"'($|:)"';
    echo "then";
    echo "    export PATH=\$PATH:$abs_gobin";
    echo "fi"; } >> "$abs_profiled"

    local user_gobin=
    [ -n "$GOPATH" ] && user_gobin=$(echo "$GOPATH" | awk -F: '{print $1}')/bin
    # shellcheck disable=SC2016
    [ -z "$user_gobin" ] && user_gobin='$HOME/go/bin'         ;# we want $HOME literal

    msg profile_path_add: issuing "$user_gobin" to "$abs_profiled"
    { echo 'if ! echo "$PATH" | grep -Eq "(^|:)'"$user_gobin"'($|:)"';
    echo "then";
    echo "    export PATH=\$PATH:$user_gobin";
    echo "fi"; } >> "$abs_profiled"

    if [ "$abs_goroot" != $default_goroot ]; then
        msg profile_path_add: setting up custom GOROOT="$abs_goroot" to "$abs_profiled"
        echo "export GOROOT=$abs_goroot" >> "$abs_profiled"
    fi
    echo "# $path_mark: end" >> "$abs_profiled"

    chmod 755 "$abs_profiled"
}

running_as_root() {
	[ "$EUID" -eq 0 ]
}

perm_build_cache() {
	local buildcache
	buildcache=$($abs_gotool env GOCACHE)

	local own
	own=":"

	if running_as_root; then
		# running as root - try user id from sudo
		buildcache=$(sudo -i -u "$SUDO_USER" "$abs_gotool" env GOCACHE)
		own="$SUDO_UID:$SUDO_GID"
	fi

	if [ "$own" == ":" ]; then
		# try getting the usual user id
		own=$(id -u):$(id -g)
	fi

	msg recursively forcing build cache ["$buildcache"] ownership to "$own"
	chown -R "$own" "$buildcache"
}

unsudo() {
	if running_as_root; then
		# shellcheck disable=SC2068
		msg unsudo: running_as_root:"$SUDO_USER": $@
		# shellcheck disable=SC2068
		sudo -i -u "$SUDO_USER" $@
	else
		# shellcheck disable=SC2068
		msg unsudo: non_root: $@
		# shellcheck disable=SC2068
		$@
	fi
}

test_runhello() {
    local ret=1
    local t="$abs_gotool version"
    if [ "$abs_goroot" != $default_goroot ]; then
        msg testing: GOROOT="$abs_goroot" "$t"
        # shellcheck disable=SC2086
        GOROOT=$abs_goroot unsudo $t | log_stdin
        ret=$?
    else
        msg testing: "$t"
        # shellcheck disable=SC2086
        unsudo $t | log_stdin
        ret=$?
    fi
    if [ $ret -eq 0 ]; then
        msg "$t": SUCCESS
    else
        msg "$t" FAIL
    fi

    local hello_tmp=
    hello_tmp=$(unsudo mktemp -t hello-tmpXXXXXXXX)".go"

    unsudo tee "$hello_tmp" >/dev/null <<__EOF__
package main
import (
    "fmt"
    "runtime"
)
func main() {
	fmt.Printf("hello, world - %s\n", runtime.Version())
}
__EOF__

    local abs_hello=
    abs_hello=$(solve "$hello_tmp")
    ret=1
    t="$abs_gotool run $abs_hello"
    if [ "$abs_goroot" != $default_goroot ]; then
        msg testing: GOROOT="$abs_goroot" "$t"
        # shellcheck disable=SC2086
        GOROOT=$abs_goroot unsudo $t | log_stdin
        ret=$?
    else
        msg testing: "$t"
        # shellcheck disable=SC2086
        unsudo $t | log_stdin
        ret=$?
    fi
    if [ $ret -eq 0 ]; then
        msg "$t": SUCCESS
    else
        msg "$t" FAIL
    fi

    rm "$hello_tmp"
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

    profile_path_remove
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

check_package() {
    if has_cmd dpkg && dpkg -s golang-go 2>/dev/null | grep ^Status | grep -q installed; then
	msg warning: golang-go is installed, you should remove it: sudo apt remove golang-go
    fi
    if has_cmd rpm && rpm -q golang >/dev/null 2>/dev/null; then
	msg warning: golang is installed, you should remove it: sudo yum remove golang
    fi
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
    -declutter)
	declutter="true"
	;;
    '')
	;;
    *)
	msg unknown option: "$1"
	echo >&2 usage: "$me [-v] [remove] [-declutter]"
	exit 1
	;;
esac

show_vars | log_stdin
check_package

cd "$destination" || die could not enter destination="$destination"

msg will install golang "$label" as: "$abs_goroot"

download
remove_old_link
untar
relink
remove_old_install
profile_path_add

msg golang "$label" installed at: "$abs_goroot"

test_runhello
if running_as_root; then
	msg running_as_root: yes
	perm_build_cache ;# must come after test, since testing might create root:root files
else
	msg running_as_root: no
fi
cleanup

exit 0

#
# main section: end
#
