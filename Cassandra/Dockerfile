# vim:set ft=dockerfile:
FROM library/cassandra

EXPOSE 7000 7001 7199 9042 9160
CMD ["cassandra", "-f"]

COPY schema.cql /schema.cql

