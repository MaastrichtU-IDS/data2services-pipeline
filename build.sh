#!/bin/bash

wget -O apache-drill/apache-drill-1.13.0.tar.gz -nc ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz
wget -O graphdb/graphdb-free-8.6.0-dist.zip -nc http://go.pardot.com/e/45622/38-graphdb-free-8-6-0-dist-zip/5pyc3s/1295914437

docker build -t apache-drill ./apache-drill
docker build -t autodrill ./AutoDrill
docker build -t r2rml ./r2rml
docker build -t xml2rdf ./xml2rdf
docker build -t rdf-upload ./RdfUpload
docker build -t graphdb ./graphdb
