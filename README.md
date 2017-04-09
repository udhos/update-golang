[![license](http://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/udhos/update-golang/blob/master/LICENSE)

# update-golang
update-golang is a script to easily fetch and install new Golang releases

Usage
=====

    git clone https://github.com/udhos/update-golang
    cd update-golang
    sudo ./update-golang.sh

Caution
=======

Before running the script, make you sure you have an untampered copy by verifying the SHA256 checksum.

    $ wget -O hash.txt https://raw.githubusercontent.com/udhos/update-golang/master/update-golang.sh.sha256
    $ sha256sum -c hash.txt

Example
=======

    $ sudo ./update-golang.sh
    SOURCE=https://storage.googleapis.com/golang
    DESTINATION=/usr/local
    RELEASE=1.8.1
    OS=linux
    ARCH=amd64
    update-golang.sh: will install golang go1.8.1.linux-amd64 as: /usr/local/go
    update-golang.sh: https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz is remote
    --2017-04-11 12:27:02--  https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz
    Resolving storage.googleapis.com (storage.googleapis.com)... 216.58.222.112
    Connecting to storage.googleapis.com (storage.googleapis.com)|216.58.222.112|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 91277742 (87M) [application/x-gzip]
    Saving to: ‘go1.8.1.linux-amd64.tar.gz’

    go1.8.1.linux-amd64.tar.gz                        100%[==========================================================================================================>]  87,05M  11,2MB/s    in 8,2s

    2017-04-11 12:27:11 (10,6 MB/s) - ‘go1.8.1.linux-amd64.tar.gz’ saved [91277742/91277742]

    update-golang.sh: remove old link: /usr/local/go
    update-golang.sh: untar: rm -rf /usr/local/go1.8.1.linux-amd64
    update-golang.sh: untar: tar xf /usr/local/go1.8.1.linux-amd64.tar.gz
    update-golang.sh: untar: rm /usr/local/go1.8.1.linux-amd64.tar.gz
    update-golang.sh: golang go1.8.1.linux-amd64 installed at: /usr/local/go
    update-golang.sh: remember to add /usr/local/go/bin to your PATH
    $

Customization
=============

These environment variables are available for customization:

    SOURCE=https://storage.googleapis.com/golang
    DESTINATION=/usr/local
    RELEASE=1.8.1
    OS=linux
    ARCH=amd64

Example:

    $ sudo RELEASE=1.8 ./update-golang.sh

