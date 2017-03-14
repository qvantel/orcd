Project Introduction
====================
The aim of this project is to evaluate if it is possible to handle real-time data in a microservice environment. Fake generated CDR data will be "streamed" into a Cassandra database, the data will be fetched from the database and aggregated, the data will then be pushed into the time series database Graphite. To visualize the data, Grafana will be used.

=====================
Architecture Overview
=====================

.. image:: _static/Architecture.png
        :align: center



==========
Main Goals
==========

*   Worldmap
    * Visualize roaming calls on a geographical map in near real time.
*   Heatmap
    * Visualize product usage on a HeatMap in near real time.
