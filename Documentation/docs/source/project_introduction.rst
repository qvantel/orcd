Project Introduction
====================
The aim of this project is to evaluate if it is possible to handle real-time data in a microservice environment. Fake generated CDR data will be "streamed" into a Cassandra database, the data will be fetched from the database and aggregated, the data will then be pushed into the time-series database Graphite. To visualize the data, Grafana will be used.

=====================
Architecture Overview
=====================

.. image:: _static/Architecture.png
        :align: center



==========
Main Goals
==========

* Worldmap
    * Visualize roaming calls on a geographical map in near real time.

* Heatmap
    * Visualize product usage on a HeatMap in near real time.

* Cassandra health metrics & dashboard views
    * Visualize health metrics from Cassandra.


==============
Research goals
==============

1. Grafana: panel plugin for "hierarchial traffic lights". To be used in visualizing managed business process status with multiple sub-items with their own statuses & threshholds.
2. Service availability metrics in orchestrated environment (via Consul) & Grafana visualization via traffic lights.
3. Adding annotation data from Elasticsearch to Grafana graphs.
4. Grafana: Investigate/experiment how to visualize dependency graphs with health info between several dependant services.
5. Possibilties to auto-genrate metrics documentation from instrumented sources? (Metric name, description etc)
6. How to fetch JIRA ticket information as metrics to time-series db and to Grafana dashboards. E.g. amount of open trouble tickets filtered by X, total duration of open cases in time period.
7. Graphite: Experiment grahpite time-series db with Cassandra storage backend for scaling & perf.
8. Investigate SNAP(Intel's modular telemetry framework), what benefits that could bring?
9. Investigate/experiment anomaly detection & alerting based on outliers compared to histroical trend on time-series metrics data.
10. More far-reaching: investigate how we could apply machine learning/pattern recognition & real time analytics to detect and alert on potential early indicators with time-series metrics data.

