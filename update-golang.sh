#!/bin/bash
#
# update-golang is a script to easily fetch and install new Golang releases
#
# Home: https://github.com/udhos/update-golang

version=0.1

me=`basename $0`
msg() {
    echo >&2 $me: $*
}

msg version $version

# defaults
source=https://storage.googleapis.com/golang
destination=/usr/local
release=1.8.1

os=`uname -s | tr [:upper:] [:lower:]`

arch=`uname -m`
case "$arch" in
    i*)
	arch=386
	;;
    x*)
        arch=amd64
	;;
esac

[ -n "$SOURCE" ] && source=$SOURCE
[ -n "$DESTINATION" ] && destination=$DESTINATION
[ -n "$RELEASE" ] && release=$RELEASE
[ -n "$OS" ] && os=$OS
[ -n "$ARCH" ] && arch=$ARCH

cat >&2 <<EOF
SOURCE=$source
DESTINATION=$destination
RELEASE=$release
OS=$os
ARCH=$arch
EOF

label=go$release.$os-$arch
filename=$label.tar.gz
url=$source/$filename
goroot=$destination/go
filepath=$destination/$filename
new_install=$destination/$label

save_dir=$PWD
cleanup() {
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

download() {
    if echo $url | egrep -q '^https?:'; then
	msg $url is remote
	local f=`solve $filepath`
	if [ -f "$f" ]; then
	    msg no need to download - file cached: $f
	else
	    wget -O $filename $url || die could not download using wget from: $url
	fi
    else
	local u=`solve $url`
	msg $u is local
	cp $u . || die could not copy from: $u
    fi
}

remove_old_link() {
    g=`solve $goroot`
    msg remove old link: $g
    [ -r $g ] && rm $g
    [ -r $g ] && die could not remove existing golang directory: $g
}

untar() {
    local l=`solve $new_install`
    msg untar: rm -rf $l
    rm -rf $l
    local f=`solve $filepath`
    msg untar: tar xf $f
    tar xf $f || die could not untar: $f
}

relink() {
    local l=`solve $new_install`
    local g=`solve $goroot`
    mv $g $l
    ln -s $l $g
}

path() {
    local b=`solve $goroot/bin`
    local p=/etc/profile.d/golang_path.sh
    msg issuing path $b to $p
    echo "export PATH=\$PATH:$b" > $p
    if [ "$b" != /usr/local/go/bin ]; then
	msg setting up custom GOROOT=$b to $p
	echo "export GOROOT=$b" >> $p
    fi
}

test() {
    local gotool=`solve $goroot/bin/go`
    msg testing $gotool:
    if $gotool version; then
	msg SUCCESS
    else
	msg FAIL
    fi
}

symlink_test() {
    file $1 | grep -q symbolic
}

symlink_get() {
    file $1 | awk '{print $NF}'
}

#
# main section: begin
#

msg will install golang $label as: `solve $goroot`

cd $destination || die could not enter destination=$destination

download
g=`solve $goroot`
if symlink_test $g; then
    old_install=`symlink_get $g`
    msg found symlink for old install: $old_install
else
    msg not found symlink for old install
fi
remove_old_link
untar
relink
if [ -n "$old_install" ]; then
    n=`solve $new_install`
    if [ "$old_install" != "$n" ]; then
	# remove only install only if it actually changed
	msg removing old install: $old_install
	rm -r $old_install
    fi
fi
path

msg golang $label installed at: `solve $goroot`

test
cleanup

#
# main section: end
#
