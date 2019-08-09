#!/bin/bash

if ! [ -f apache-drill/apache-drill-1.15.0.tar.gz ]; then
  curl http://apache.40b.nl/drill/drill-1.15.0/apache-drill-1.15.0.tar.gz -o apache-drill/apache-drill-1.15.0.tar.gz
fi

docker build -t apache-drill ./apache-drill
docker build -t autor2rml ./AutoR2RML
docker build -t r2rml ./r2rml
docker build -t xml2rdf ./xml2rdf
docker build -t rdf-upload ./RdfUpload
docker build -t graphdb ./graphdb
docker pull vemonet/data2services-sparql-operations
docker pull vemonet/data2services-download
