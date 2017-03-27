# vim:set ft=dockerfile:
FROM library/cassandra

EXPOSE 7000 7001 7199 9042 9160

COPY graphite.yaml /etc/cassandra/

RUN echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.metricsReporterConfigFile=graphite.yaml\"" >> /etc/cassandra/cassandra-env.sh

COPY metrics-graphite-3.1.0.jar /usr/share/cassandra/lib/

CMD ["cassandra", "-f"]

COPY schema.cql /schema.cql

