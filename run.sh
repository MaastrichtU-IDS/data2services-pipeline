#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

FILEPATH=$1

if [ -z "$2" ]
then
  DRILL=172.17.0.2
else
  DRILL=$2
fi

if [ -z "$3" ]
then
  GRAPHDB=http://172.17.0.3
else
  GRAPHDB=$3
fi

echo $FILEPATH
echo "Drill: $DRILL"
echo "GraphDB: $GRAPHDB"

docker run -it --rm --link drill:drill autodrill -h $DRILL -r /data/$FILEPATH/drill > /data/$FILEPATH/mappings.ttl

# Generate config.properties
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = /data/$FILEPATH/mappings.ttl
outputFile = /data/$FILEPATH/rdf_output.ttl.gz
format = TTL" >> /data/$FILEPATH/config.properties

# Run r2rml to generate RDF files
docker run -it --rm --link drill:drill -v /data:/data r2rml /data/$FILEPATH/config.properties

# Unzip generated RDF file
gzip -d -k -f /data/$FILEPATH/rdf_output.ttl.gz

# Run RdfUpload to upload to GraphDB
docker run -it --rm -v /data/$FILEPATH:/data rdf-upload \
  -if "/data/rdf_output.ttl" \
  -ep "$GRAPHDB:7200/repositories/kraken_test" \
  -uep "$GRAPHDB:7200/repositories/kraken_test/statements" \
  -un admin -pw admin


docker run -it --rm -v /data:/data rdf-upload \
  -if "/data/pharmgkb_drugs/rdf_output.ttl" \
  -ep "http://172.17.0.3:7200/repositories/kraken_test" \
  -uep "http://172.17.0.3:7200/repositories/kraken_test/statements" \
  -un admin -pw admin