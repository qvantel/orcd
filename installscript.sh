#!/bin/bash

if [[ $OSTYPE == *"darwin"* ]]; then
    which -s brew
    if [[ $? != 0 ]] ; then
        # Install Homebrew
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        brew update
    fi
    brew install md5sha1sum
    brew install git
    brew install sbt
    brew install wget
    brew install node # Will install npm as well
    brew install docker
    brew cask install java
    npm install -g grunt
else
    # Check that the distro is debian based
    ubuntu=0
    cat /etc/os-release | grep -q ubuntu && ubuntu=1
    if [ "$ubuntu" -ne 1 ]; then
        echo "This script is only supported on ubuntu-based linux distributions"
        exit 1
    fi

    # Tools
    sudo apt-get install -y vim git

    # Sbt and Java
    echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt.list
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
    sudo apt-get update
    sudo apt-get -y install sbt openjdk-8-jdk

    # Npm
    sudo apt-get install -y npm
    sudo npm install -g grunt

    # Docker
    sudo apt-get install -y docker.io
fi


