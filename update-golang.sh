#!/bin/bash
#
# update-golang is a script to easily fetch and install new Golang releases
#
# Home: https://github.com/udhos/update-golang

version=0.4

me=`basename $0`
msg() {
    echo >&2 $me: $*
}

log_stdin() {
    while read i; do
	msg $i
    done
}

# defaults
source=https://storage.googleapis.com/golang
destination=/usr/local
release=1.8.1
profiled=/etc/profile.d/golang_path.sh

os=`uname -s | tr [:upper:] [:lower:]`

arch=`uname -m`
case "$arch" in
    a*)
	arch=armv6l
	;;
    i*)
	arch=386
	;;
    x*)
        arch=amd64
	;;
    aarch64)
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
    cat <<EOF
SOURCE=$source
DESTINATION=$destination
RELEASE=$release
OS=$os
ARCH=$arch
PROFILED=$profiled
CACHE=$cache
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
cleanup() {
    [ -n "$tmp" ] && [ -f "$tmp" ] && msg cleanup: $tmp && rm $tmp
    [ -n "$save_dir" ] && cd $save_dir
}

die() {
    msg $*
    cleanup
    exit 1
}

solve() {
    local path=$1
    if echo $path | egrep -q ^/; then
	echo $path
    else
	echo $save_dir/$path
    fi
}

abs_filepath=`solve $filepath`
abs_url=`solve $url`
abs_goroot=`solve $goroot`
abs_new_install=`solve $new_install`
abs_gobin=$abs_goroot/bin
abs_gotool=$abs_gobin/go
abs_profiled=`solve $profiled`

download() {
    if echo $url | egrep -q '^https?:'; then
	msg $url is remote
	if [ -f "$abs_filepath" ]; then
	    msg no need to download - file cached: $abs_filepath
	else
	    wget -O $abs_filepath $url || die could not download using wget from: $url
	fi
    else
	msg $abs_url is local
	cp $abs_url . || die could not copy from: $abs_url
    fi
}

symlink_test() {
    file $1 | grep -q symbolic
}

symlink_get() {
    file $1 | awk '{print $NF}'
}

remove_old_link() {
    if symlink_test $abs_goroot; then
	abs_old_install=`symlink_get $abs_goroot`
	msg remove_old_link: found symlink for old install: $abs_old_install
    else
	msg remove_old_link: not found symlink for old install
    fi
    
    [ -r $abs_goroot ] && rm $abs_goroot
    [ -r $abs_goroot ] && die could not remove existing golang directory: $abs_goroot
}

untar() {
    if [ -d "$abs_new_install" ]; then
	msg untar: rm -r $abs_new_install
	rm -r $abs_new_install || die untar: could not remove: $abs_new_install
    fi
    [ -d "$PWD" ] || die untar: not a directory: $PWD
    [ -w "$PWD" ] || die untar: unable to write: $PWD
    local cmd="tar -x --no-ignore-command-error -f $abs_filepath"
    msg untar: $cmd
    $cmd || die untar: failed: $abs_filepath
}

relink() {
    mv $abs_goroot $abs_new_install
    ln -s $abs_new_install $abs_goroot
}

path_mark=update-golang.sh

path_remove() {
    if [ -f "$abs_profiled" ]; then
	msg path: removing old settings from: $abs_profiled
	tmp=`mktemp -t` ;# save for later removal
	if [ ! -f "$tmp" ]; then
	    msg path: could not create temporary file: $tmp
	    return
	fi
	grep -v $path_mark $abs_profiled > $tmp 
	cp $tmp $abs_profiled
    fi
}

default_goroot=/usr/local/go

path() {
    path_remove
    
    msg path: issuing new $abs_gobin to $abs_profiled
    local dont_edit=";# DOT NOT EDIT: installed by $path_mark"
    echo "export PATH=\$PATH:$abs_gobin $dont_edit" >> $abs_profiled
    if [ "$abs_goroot" != $default_goroot ]; then
	msg path: setting up custom GOROOT=$abs_goroot to $abs_profiled
	echo "export GOROOT=$abs_goroot $dont_edit" >> $abs_profiled
    fi
}

test() {
    local ret=1
    local t="$abs_gotool version"
    if [ "$abs_goroot" != $default_goroot ]; then
        msg testing: GOROOT=$abs_goroot $t
	GOROOT=$abs_goroot $t | log_stdin
	ret=$?
    else
        msg testing: $t
	$t | log_stdin
	ret=$?
    fi
    if [ $ret -eq 0 ]; then
	msg $t: SUCCESS
    else
	msg $t FAIL
    fi

    local abs_hello=`solve hello.go`
    ret=1
    t="$abs_gotool run $abs_hello"
    if [ "$abs_goroot" != $default_goroot ]; then
        msg testing: GOROOT=$abs_goroot $t
	GOROOT=$abs_goroot $t | log_stdin
	ret=$?
    else
        msg testing: $t
	$t | log_stdin
	ret=$?
    fi
    if [ $ret -eq 0 ]; then
	msg $t: SUCCESS
    else
	msg $t FAIL
    fi
}

remove_golang() {
    if symlink_test $abs_goroot; then
	local old_install=`symlink_get $abs_goroot`
	msg found symlink for old install: $old_install
	msg removing symlink: $abs_goroot
	rm $abs_goroot
	msg removing old install: $old_install
	rm -r $old_install
    else
	msg not found symlink for old install
    fi

    path_remove
}

remove_old_install() {
    if [ -n "$abs_old_install" ]; then
	if [ "$abs_old_install" != "$abs_new_install" ]; then
	    # remove old install only if it actually changed
	    msg removing old install: $abs_old_install
	    rm -r $abs_old_install
	fi
    fi
}

show_version() {
    msg version $version
}

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
	msg unknown option: $1
	echo >&2 usage: $me [-v] [remove]
	exit 1
	;;
esac

show_version

show_vars | log_stdin

msg will install golang $label as: $abs_goroot

cd $destination || die could not enter destination=$destination

download
remove_old_link
untar
relink
remove_old_install
path

msg golang $label installed at: $abs_goroot

test
cleanup

#
# main section: end
#
