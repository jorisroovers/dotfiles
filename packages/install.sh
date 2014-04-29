#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root"
    exit 1
fi

echo "Installing JDK 7"
sudo apt-get install -y openjdk-7-jdk


