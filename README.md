[![Build Status](https://travis-ci.org/qvantel/orcd.svg?branch=master)](https://travis-ci.org/qvantel/orcd)

orcD
=======
`orcD`, or `Operational Rated CDR Dashboard` is a proof of concept to visualize rated [CDR's](https://en.wikipedia.org/wiki/Call_detail_record) on a heat and world map. The HeatMap is visualizing CDR's that has gone through some rating/billing system which has a product tied to it, which is visualized in the HeatMap. The GeoMap visualizes rated CDR's which has a roaming status in the record.

### Backend

A set of docker containers that generates CDR records into Cassandra, syncs the cassandra CDR records to Graphite/Carbon and is then accessed from the frontend GUI.

Containers:
- CDRGenerator
- Cassandra
- DBConnector
- Graphite/Carbon

**Team members:** Johan Bjäreholt, Robin Flygare, Gorges Gorges, Erik Lilja, Max Meldrum, Niklas Doung, Jozef Miljak and Martin Svensson.

### Frontend

A single Grafana container with a few plugins that fetches data from the graphite docker container.

Plugins:
- GeoMap
- Heatmap
- Cassandra Health

**Team members:** Dennis Rojas, Rasmus Appelqvist, Tord Eliasson, Per Lennartsson, Filip Stål, Oliver Örnmyr and Kim Sand.

## Sub repositories

For more information about each component, please check their git repositories respective README.md

## Installation

In this section, we'll go through how to setup the pipeline. It will cover dependencies, how to manage containers and how to use the system.

### Cloning the repository

The first thing we'll need to do is to clone the master repository. To clone the repository run:
```
git clone https://github.com/qvantel/orcd.git
```

The repository contains a set of subrepositories, to fetch the subrepositories you can run:
```
git submodule update --init --recursive --remote
git submodule foreach -q --recursive 'branch="$(git config -f $toplevel/.gitmodules submodule.$name.branch)"; git checkout $branch; git pull'
```

### Dependencies
In order to install everything and get it up and running, you'll first need to download and install some dependencies. This can be done manually or by running the following command for debian based distros and MacOS:

```
./installscript.sh
```

The dependencies you will need are:
- Git
- Docker
- SBT
- Java
- NPM
- NodeJS
- Grunt

If you get the error "node is not installed" even though it is; it can be worked around by symlinking nodejs to node:
```
sudo ln -s /usr/bin/nodejs /usr/bin/node
```

### The Docker container script
In the root folder, you'll see a script called **containers.sh**. This script manages all the required docker containers in order to maintain the pipeline (Generator -> Cassandra -> DBConnector -> Graphite -> Grafana). This script can **start**, **stop** and **remove** containers.

**Important**: our containerscript requires you to have the permission as normal user to run docker commands. This means you can't run `containers.sh` as root. To make your user be able to run docker commands, [please visit this wiki page.](https://github.com/flygare/orcd/wiki/Docker-Help)

To start all the containers run the following command:
```
./containers.sh start
```

To stop all containers:
```
./containers.sh stop
```

To stop and then remove all the containers:
```
./containers.sh clean
```

You can also specify a specific container for the three previously mentioned commands:
```
./containers.sh start frontend
./containers.sh stop frontend
./containers.sh clean frontend
```

The containers maintained by this script are:
- cdrgenerator
- cassandra
- dbconnector
- graphite
- frontend (Grafana)

However, what we want to do now is to run the start command:
```
./containers.sh start
```

This may take a while as it will download, install and startup everything needed within each container. If everything worked as expected, you should have the 5 previously mentioned docker containers up and running.


### Usage of the system
If you now navigate to http://localhost:3000 you should access your webserver containing Grafana. You will be greeted with a login screen, you can login with **admin** as username and **admin** as password. The two plugins contained in the frontend repository (GeoMap and Heatmap) are pre-installed and can be found in their respective pre-set dashboards.

You can also navigate to http://localhost:2000 to directly access your webserver containing Graphite.

### Testing
#### Unit tests
For the CDRGenerator and the DBConnector we have implemented various test cases for unit testing.

#### Integration tests
We have some bash scripts that tests the CDRGenerator -> Cassandra -> DBConnector -> Graphite path.
There is also a python script that tests this pipeline.

All of the integration tests lies in the `test` directory.
