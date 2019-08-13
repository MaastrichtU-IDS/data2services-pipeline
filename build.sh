#!/bin/bash

if ! [ -f apache-drill/apache-drill-1.15.0.tar.gz ]; then
  curl http://apache.40b.nl/drill/drill-1.15.0/apache-drill-1.15.0.tar.gz -o apache-drill/apache-drill-1.15.0.tar.gz
fi

docker build -t apache-drill ./apache-drill
docker build -t graphdb ./graphdb
docker pull vemonet/autor2rml
docker pull vemonet/r2rml
docker pull vemonet/xml2rdf
docker pull vemonet/rdf-upload
docker pull vemonet/data2services-sparql-operations
docker pull vemonet/data2services-download
