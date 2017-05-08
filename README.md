Qvantel
=======

### Backend

A set of docker containers that generates CDR records into CassandraDB, syncs the cassandra CDR records to Graphite/Carbon and is then accessed from the frontend

Containers:
- CDRGenerator
- CassandraDB
- DBConnector
- Graphite/Carbon
- REST backend

**Team members:** Johan Bjäreholt, Robin Flygare, Gorges Gorges, Erik Lilja, Max Meldrum, Niklas Doung, Jozef Miljak and Martin Svensson

### Frontend

A single Grafana container with a few plugins that fetches data from the graphite docker container.

Plugins:
- Worldmap
- Heatmap

**Team members:** Dennis Rojas, Rasmus Appelqvist, Tord Eliasson, Per Lennartsson, Filip Stål, Oliver Örnmyr, Kim Sand

## Sub repositories

For more information about each component, please check their git repositories respective README.md

## Installation

In this section, we'll go through how to setup the pipeline. It will cover dependencies, how to manage containers and how to use the system.

### Dependencies
In order to install everything and get it up and running, you'll first need to download and install some dependencies:
- Git
- Docker
- SBT
- Java
- NPM
- NodeJS

This can be done by running the following command for debian based distros:
```
./installscript.sh
```
If you get the error "node is not installed" even though it is; it can be worked around by symlinking nodejs to node:
```
sudo ln -s /usr/bin/nodejs /usr/bin/node
```

When you have installed the dependencies, you'll need to clone this repository and fetch the subrepositories.

To clone the repository run:
```
git clone https://github.com/flygare/Qvantel.git
```

To fetch the subrepositories you can run:
```
git submodule update --init --recursive --remote
git submodule foreach -q --recursive 'branch="$(git config -f $toplevel/.gitmodules submodule.$name.branch)"; git checkout $branch'
```

### The Docker container script
In the root folder, you'll see a script called **containers.sh**. This script manages all the required docker containers in order to maintain the pipeline (CDR -> Cassandra -> DBConnector -> Graphite -> Grafana) (?). This script can **start**, **stop** and **remove** containers.

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
If you now navigate to http://localhost:3000 you should access your webserver containing Grafana. You will be greeted with a login screen, you can login with **qvantel** as username and **qvantel** as password. The two plugins contained in the frontend repository (GeoMap and Heatmap) are pre-installed and can be found in their respective pre-set dashboards.

You can also navigate to http://localhost:2000 to directly access your webserver containing Graphite.

### Testing
## Unit tests
For the CDRGenerator and the DBConnector we have implemented various test cases for unit testing.

## Integration tests
We have some bash scripts that tests the CDRGenerator -> Cassandra -> DBConnector -> Graphite path.
There is also a python script that tests this pipeline.

All of the integration tests lies in the `test` directory.
