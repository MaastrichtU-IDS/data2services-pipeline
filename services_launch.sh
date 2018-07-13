#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
# true statement to avoid getting an error if container does not exist 
docker stop drill &> /dev/null || true
docker rm drill &> /dev/null || true

#docker stop graphdb &> /dev/null || true
#docker rm graphdb &> /dev/null || true


docker run -dit -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill

docker run --detach \
    --name graphdb \
    --publish 7200:7200 \
    --volume /data/graphdb:/opt/graphdb/home \
    --volume /data/graphdb-import:/root/graphdb-import \
    --restart unless-stopped \
    graphdb:8.6.0

echo "Apache Drill running"
docker inspect drill | grep -m 1 "\"IPAddress\""

echo "GraphDB running"
docker inspect graphdb | grep -m 1 "\"IPAddress\""