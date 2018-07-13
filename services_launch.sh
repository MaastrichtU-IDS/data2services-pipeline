#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately


docker stop graphdb || true
docker rm graphdb || true

docker stop drill || true
docker rm drill || true


docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill

docker run --detach \
    --name graphdb \
    --publish 7200:7200 \
    --volume /data/graphdb:/opt/graphdb/home \
    --volume /data/graphdb-import:/root/graphdb-import \
    --restart unless-stopped \
    graphdb:8.6.0

echo "Apache Drill"
docker inspect drill | grep -m 1 "\"IPAddress\""

echo "GraphDB"
docker inspect graphdb | grep -m 1 "\"IPAddress\""