[![license](http://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/udhos/update-golang/blob/master/LICENSE)
[![Travis Build Status](https://travis-ci.org/udhos/update-golang.svg?branch=master)](https://travis-ci.org/udhos/update-golang)
[![asciicast](https://asciinema.org/a/INSenxRRfgfC9TgO1jq9zVk8a.png)](https://asciinema.org/a/INSenxRRfgfC9TgO1jq9zVk8a)

# update-golang
update-golang is a script to easily fetch and install new Golang releases with minimum system intrusion.

Table of Contents
=================

  * [How it works](#how-it-works)
  * [Usage](#usage)
  * [Caution](#caution)
  * [Example](#example)
  * [Customization](#customization)
  * [Per\-user Install](#per-user-install)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go)

How it works
============

This is the default behavior:

1\. The script uses local system OS and ARCH to download the correct binary release. It is not harmful to run the script multiple times. Downloaded releases are kept as cache under '/usr/local'. You can erase them manually.

2\. The release is installed at '/usr/local/go'.

3\. The path '/usr/local/go/bin' is added to PATH using '/etc/profile.d/golang_path.sh'.

4\. Only if needed, GOROOT is properly setup, also using '/etc/profile.d/golang_path.sh'.

You can customize the behavior by setting environment variables (see Customization below).

Usage
=====

    git clone https://github.com/udhos/update-golang
    cd update-golang
    sudo ./update-golang.sh

Caution
=======

Before running the script, make sure you have an untampered copy by verifying the SHA256 checksum.

    $ wget -qO hash.txt https://raw.githubusercontent.com/udhos/update-golang/master/update-golang.sh.sha256
    $ sha256sum -c hash.txt
    update-golang.sh: OK

Example
=======

    $ sudo ./update-golang.sh
    update-golang.sh: version 0.8
    update-golang.sh: user: uid=0(root) gid=0(root) groups=0(root)
    update-golang.sh: SOURCE=https://storage.googleapis.com/golang
    update-golang.sh: DESTINATION=/usr/local
    update-golang.sh: RELEASE=1.8.3
    update-golang.sh: OS=linux
    update-golang.sh: ARCH_PROBE=uname -m
    update-golang.sh: ARCH=amd64
    update-golang.sh: PROFILED=/etc/profile.d/golang_path.sh
    update-golang.sh: CACHE=/usr/local
    update-golang.sh: GOPATH=
    update-golang.sh: DEBUG=
    update-golang.sh: will install golang go1.8.3.linux-amd64 as: /usr/local/go
    update-golang.sh: https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz is remote
    --2017-06-26 17:56:13--  https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz
    Resolving storage.googleapis.com (storage.googleapis.com)... 172.217.29.176
    Connecting to storage.googleapis.com (storage.googleapis.com)|172.217.29.176|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 90029041 (86M) [application/x-gzip]
    Saving to: ‘/usr/local/go1.8.3.linux-amd64.tar.gz’

    /usr/local/go1.8.3.linux-amd64.tar.gz  100%[=========================================================================>]  85.86M  11.3MB/s    in 8.3s

    2017-06-26 17:56:22 (10.4 MB/s) - ‘/usr/local/go1.8.3.linux-amd64.tar.gz’ saved [90029041/90029041]

    update-golang.sh: remove_old_link: found symlink for old install: /usr/local/go1.8.3.linux-amd64
    update-golang.sh: untar: rm_dir /usr/local/go1.8.3.linux-amd64
    update-golang.sh: untar: tar -x -f /usr/local/go1.8.3.linux-amd64.tar.gz
    update-golang.sh: path: removing old settings from: /etc/profile.d/golang_path.sh
    update-golang.sh: path: issuing new /usr/local/go/bin to /etc/profile.d/golang_path.sh
    update-golang.sh: path: issuing /home/lab/go/bin to /etc/profile.d/golang_path.sh
    update-golang.sh: golang go1.8.3.linux-amd64 installed at: /usr/local/go
    update-golang.sh: testing: /usr/local/go/bin/go version
    update-golang.sh: go version go1.8.3 linux/amd64
    update-golang.sh: /usr/local/go/bin/go version: SUCCESS
    update-golang.sh: testing: /usr/local/go/bin/go run /tmp/hello-tmpkm4kq4dB.go
    update-golang.sh: hello, world
    update-golang.sh: /usr/local/go/bin/go run /tmp/hello-tmpkm4kq4dB.go: SUCCESS
    update-golang.sh: cleanup: /tmp/tmp.cDSO2HTGvV
    $

Customization
=============

These environment variables are available for customization:

    SOURCE=https://storage.googleapis.com/golang ;# download location
    DESTINATION=/usr/local                       ;# install destination
    RELEASE=1.8.3                                ;# golang release
    OS=linux                                     ;# os
    ARCH_PROBE=uname -m                          ;# arch detection
    ARCH=amd64                                   ;# arch
    PROFILED=/etc/profile.d/golang_path.sh       ;# update PATH, optionally set GOROOT
    CACHE=/usr/local                             ;# cache downloads
    GOPATH=
    DEBUG=


Example:

    $ sudo RELEASE=1.9beta1 ./update-golang.sh

Per-user Install
================

Default behavior is to install Golang globally for all system users.

However you can use the environment variables to point locations to your per-user home directory.

Example:

    This example will install Golang under ~/golang for current user only.
    
    $ mkdir ~/golang
    $ DESTINATION=~/golang PROFILED=~/.profile ./update-golang.sh

END
