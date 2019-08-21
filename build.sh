#!/bin/bash

docker build -t graphdb ./graphdb
docker pull vemonet/apache-drill
docker pull vemonet/autor2rml
docker pull vemonet/r2rml
docker pull vemonet/xml2rdf
docker pull vemonet/rdf-upload
docker pull vemonet/data2services-sparql-operations
docker pull vemonet/data2services-download
