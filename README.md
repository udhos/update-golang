# update-golang
update-golang is a script to easily fetch and install new Golang releases

Usage
=====

    git clone https://github.com/udhos/update-golang
    cd update-golang
    sudo ./update-golang.sh

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
    --2017-04-11 12:02:14--  https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz
    Resolving storage.googleapis.com (storage.googleapis.com)... 216.58.222.112
    Connecting to storage.googleapis.com (storage.googleapis.com)|216.58.222.112|:443... connected.
    HTTP request sent, awaiting response... 200 OK
    Length: 91277742 (87M) [application/x-gzip]
    Saving to: ‘go1.8.1.linux-amd64.tar.gz’
    
    go1.8.1.linux-amd64.tar.gz                        100%[==========================================================================================================>]  87,05M  11,2MB/s    in 8,0s
    
    2017-04-11 12:02:23 (10,8 MB/s) - ‘go1.8.1.linux-amd64.tar.gz’ saved [91277742/91277742]
    
    update-golang.sh: golang go1.8.1.linux-amd64 installed at: /usr/local/go
    update-golang.sh: add /usr/local/go/bin to your PATH

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

