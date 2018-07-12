#!/bin/bash

FILEPATH=$1

if [ -z "$2" ]
then
  HOST=172.17.0.2
else
  HOST=$2
fi

echo $FILEPATH
echo $HOST

#docker run -it --rm --link drill:drill autodrill -h $HOST -r /data/$FILEPATH/drill > /data/$FILEPATH/mappings.ttl
docker run -it --rm --link drill:drill autodrill -h 172.17.0.2 -r /data/$FILEPATH/drill > /data/$FILEPATH/mappings.ttl

# Generate config.properties
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = /data/$FILEPATH/mappings.ttl
outputFile = /data/$FILEPATH/rdf_output.ttl.gz
format = TTL" >> /data/$FILEPATH/config.properties

#docker run -it --rm --link drill:drill -v /data:/data r2rml /data/pharmgkb_drugs/config.properties
docker run -it --rm --link drill:drill -v /data:/data r2rml /data/$FILEPATH/config.properties
