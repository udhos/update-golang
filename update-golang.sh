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
    path=$1
    if echo $path | egrep -q ^/; then
	echo $path
    else
	echo $save_dir/$path
    fi
}

download() {
    if echo $url | egrep -q '^https?:'; then
	msg $url is remote
	f=`solve $filepath`
	if [ -f "$f" ]; then
	    msg no need to download - file cached: $f
	else
	    wget -O $filename $url || die could not download using wget from: $url
	fi
    else
	u=`solve $url`
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
    l=`solve $destination/$label`
    msg untar: rm -rf $l
    rm -rf $l
    f=`solve $filepath`
    msg untar: tar xf $f
    tar xf $f || die could not untar: $f
}

relink() {
    l=`solve $destination/$label`
    g=`solve $goroot`
    mv $g $l
    ln -s $l $g
}

path() {
    b=`solve $goroot/bin`
    p=/etc/profile.d/golang_path.sh
    msg issuing path $b to $p
    echo "export PATH=\$PATH:$b" > $p
    if [ "$b" != /usr/local/go/bin ]; then
	msg setting up custom GOROOT=$b to $p
	echo "export GOROOT=$b" >> $p
    fi
}

msg will install golang $label as: `solve $goroot`

cd $destination || die could not enter destination=$destination

download
remove_old_link
untar
relink
path

msg golang $label installed at: `solve $goroot`

cleanup
