#!/usr/bin/bash

install_valkey() {
    echo "beginning install of valkey"
    sleep 60
    sudo yum -y install make openssl-devel gcc
    sleep 60
    wget https://github.com/valkey-io/valkey/archive/refs/tags/7.2.6.tar.gz
    tar xvzf 7.2.6.tar.gz
    cd valkey-7.2.6
    make distclean
    make valkey-cli BUILD_TLS=yes
    sudo install -m 755 src/valkey-cli /usr/local/bin/
    echo "valkey successfull installed in /usr/local/bin/"
}

which valkey-cli >/dev/null 2>&1

if [ $? -eq 0 ]
then
    echo "valkey-cli is already installed"
else
    install_valkey
fi