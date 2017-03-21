# vim:set ft=dockerfile:
FROM library/cassandra

EXPOSE 7000 7001 7199 9042 9160

COPY metrics-graphite-3.2.2.jar /usr/share/cassandra/lib/
COPY graphite.yaml /etc/cassandra/

RUN echo "JVM_OPTS=\"\$JVM_OPTS -Dcassandra.metricsReporterConfigFile=graphite.yaml\"" >> /etc/cassandra/cassandra-env.sh

CMD ["cassandra", "-f"]

COPY schema.cql /schema.cql

