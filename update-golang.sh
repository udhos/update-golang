#!/bin/bash

# defaults
destination=/usr/local
release=1.8.1
os=linux
arch=amd64

[ -n "$DESTINATION" ] && destination=$DESTINATION
[ -n "$RELEASE" ] && release=$RELEASE
[ -n "$OS" ] && os=$OS
[ -n "$ARCH" ] && arch=$ARCH

label=go$release.$os-$arch
filename=$label.tar.gz
url=https://storage.googleapis.com/golang/$filename

[ -n "$URL" ] && url=$URL

me=`basename $0`

msg() {
    echo >&2 $me: $*
}

die() {
    msg $*
    exit 1
}

download() {
    if [ -r $url ]; then
	msg $url is local
	cp $url . || die could not copy from: $url
    else
	msg $url is remote
	wget $url || die could not download from: $url
    fi
}

remove_old_link() {
    [ -r go ] && rm go
    [ -r go ] && die could not remove existing golang directory: $destination/go
}

untar() {
    rm -rf $label
    tar xf $filename || die could not untar: $filename
    rm $filename
}

relink() {
    mv go $label
    ln -s $label go
}

msg will install golang $label as: $destination/go

cd $destination || die could not enter destination=$destination

download
remove_old_link
untar
relink

msg golang $label installed at: $destination/go
msg add $destination/go/bin to your PATH
