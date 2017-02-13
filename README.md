Qvantel
=======

### Backend

Will consist of a REST backend, a Cassandra database and a Graphite database. All of which will be configured and set up with Docker containers

**Team members:** Johan Bjäreholt, Robin Flygare, Gorges Gorges, Erik Lilja, Max Meldrum, Niklas Doung, Jozed Miljak and Martin Svensson

### Frontend

Will consist of a Grafana frontend which will talk to the REST backend, which will be running in a Docker container.

**Team members:** Dennis Rojas, Rasmus Appelkvist, Tord Eliasson, Per Lennartsson, Filip Stål, Oliver Örnmyr, Kim Sand

Common commands
======

### Docker
Most of the commands need to be known are inside `containers.sh`

## Remove having to perform sudo for every docker command
`$ sudo groupadd docker` (Does not matter if the group is already added)

`$ sudo gpasswd -a student docker` (Add yourself to the docker group)

`$ sudo service docker restart` (Restart service)

***IMPORTANT:*** Remember to log out and back in for these things to be in effect.

## Run a shell or program in a container
```
$ docker exec -it CONTAINER_NAME service
```
Where service is e.g `bash/zsh/cqlsh`.


## List containers
# Running
`$ docker ps`

# Inactive/stopped
`$ docker ps -a`

## Run a docker container
```
$ docker run
		--name=some_name_the_container_is_differentiated
		-p internal_port:external_port
		-d # Run the container in detached mode. When creating it, do not have an interactive shell.
		VERSION # "Cassandra", or "grafana:4.1.1" or "backend:latest"
```
## Stop a docker container
```
```
Unsure about the name? See List containers and check the name column

## Remove a docker container
`$ docker stop NAME # Where name is the automatically created or manually chosen one.`

Unsure about the name? See List containers and check the name column


Configure HTTPS/SSH
======

Run `$ ./configure_ssh_https.sh https` or `./configure_ssh_https.sh ssh`

Pull all changes
======
Run `$ ./pullall`
Issues with SSH? Try changing to HTTPS in Configure HTTPS/SSH-section

Docker DNS issue
======
Does deploying back-end result in an issue? Let the docker container share your DNS configuration
`$ ./telenor_wifi_docker_dns_fix.sh`
