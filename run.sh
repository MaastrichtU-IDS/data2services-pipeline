#!/bin/bash

## create config file
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = /data/mapping.ttl
outputFile = /data/rdf_output.ttl.gz
format = TTL" > config.properties

## run the pipeline
docker run -it --rm --link drill:drill autodrill -h drill -r /data/pharmgkb > mapping.ttl
docker run -it --rm --link drill:drill -v $PWD:/data r2rml /data/config.properties
docker run -it --rm --link graphdb:graphdb -v $PWD:/data rdf-upload -if "/data/rdf_output.ttl.gz" -url "http://graphdb:7200" -rep "test" -un import_user -pw test
