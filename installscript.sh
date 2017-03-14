#! /bin/bash

# Check that the distro is debian based
if [ ! -f /etc/debian_version ]; then
	echo "This script is only supported on debian-based linux distributions"
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

# Docker
sudo apt-get install -y docker
