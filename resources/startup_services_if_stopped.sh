#!/bin/bash

# Start Apache Drill if not running
if [ ! "$(docker ps -q -f name=drill)" ]; then
    docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill
fi

# Start GraphDB if not running
if [ ! "$(docker ps -q -f name=graphdb)" ]; then
    docker run -d --rm --name graphdb -p 7200:7200 -v /data/graphdb:/opt/graphdb/home -v /data/graphdb-import:/root/graphdb-import graphdb
    sleep 20
fi
