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

**Team members:** Johan Bjäreholt, Robin Flygare, Gorges Gorges, Erik Lilja, Max Meldrum, Niklas Doung, Jozed Miljak and Martin Svensson

### Frontend

A single Graphana container with a few plugins that fetches data from the graphite docker container.

Plugins:
- Worldmap
- Heatmap

**Team members:** Dennis Rojas, Rasmus Appelkvist, Tord Eliasson, Per Lennartsson, Filip Stål, Oliver Örnmyr, Kim Sand
