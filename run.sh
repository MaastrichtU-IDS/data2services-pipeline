#!/bin/bash

YAML_PATH=$1

# Parse yaml
echo "---------------------------------"
echo "  YAML configuration:"
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}
eval $(parse_yaml $YAML_PATH "")


# Set default values
GRAPHDB_URL=${GRAPHDB_URL:-http://graphdb:7200}
GRAPHDB_REPOSITORY=${GRAPHDB_REPOSITORY:-test}
GRAPHDB_USERNAME=${GRAPHDB_USERNAME:-import_user}
GRAPHDB_PASSWORD=${GRAPHDB_PASSWORD:-test}
BASE_URI=${BASE_URI:-http://data2services/}


echo "Working file directory: $WORKING_DIRECTORY"
echo "JDBC URL for AutoR2RML: $JDBC_URL"
echo "JDBC DB container for AutoR2RML: $JDBC_CONTAINER"
echo "JDBC DB username for AutoR2RML: $JDBC_USERNAME"
echo "JDBC DB password for AutoR2RML: $JDBC_PASSWORD"
echo "GraphDB URL: $GRAPHDB_URL"
echo "GraphDB repository: $GRAPHDB_REPOSITORY"
echo "GraphDB username: $GRAPHDB_USERNAME"
echo "GraphDB password: $GRAPHDB_PASSWORD"

INPUT_PATH=$WORKING_DIRECTORY

if [[ $WORKING_DIRECTORY == *.xml || $WORKING_DIRECTORY == *.xml.gz ]]
then

  echo "---------------------------------"
  echo "  Running xml2rdf..."
  echo "---------------------------------"

  WORKING_DIRECTORY=$(dirname "$INPUT_PATH")

  docker run --rm -it -v /data:/data xml2rdf  -i "$INPUT_PATH" -o "$INPUT_PATH.nq.gz" -g "http://data2services/graph/xml2rdf"
  # XML file needs to be in /data. TODO: put the first part of the path as the shared volume

else

  echo "---------------------------------"
  echo "  Converting TSV to RDF..."
  echo "---------------------------------"
  echo "Running AutoR2RML..."

  ## Run AutoR2RML to generate R2RML mapping files

  # TODO: WARNING the $WORKING_DIRECTORY passed at the end is the path INSIDE the Apache Drill docker container (it must always starts with /data).
  # So this script only works with dir inside /data)
  docker run -it --rm --link $JDBC_CONTAINER:$JDBC_CONTAINER -v $WORKING_DIRECTORY:/data autor2rml -j "$JDBC_URL" -r -o /data/mapping.ttl -d "$INPUT_PATH" -u "$JDBC_USERNAME" -p "$JDBC_PASSWORD" -b "$BASE_URI" -g "http://data2services/graph/autor2rml"
  
  echo "R2RML mappings (mapping.ttl) has been generated."

  echo "Running r2rml..."

  ## Generate config.properties required for r2rml
  # TODO: Should we generate this directly in AutoR2RML? Alex: no
  sudo touch $WORKING_DIRECTORY/config.properties
  sudo chmod 777 $WORKING_DIRECTORY/config.properties
  echo "connectionURL = $JDBC_URL
  mappingFile = /data/mapping.ttl
  outputFile = /data/rdf_output.nq
  user = $JDBC_USERNAME
  password = $JDBC_PASSWORD
  format = NQUADS" > $WORKING_DIRECTORY/config.properties

  ## Run r2rml to generate RDF files. Using config.properties at the root dir of the container
  docker run -it --rm --link $JDBC_CONTAINER:$JDBC_CONTAINER -v $WORKING_DIRECTORY:/data r2rml /data/config.properties

  echo "r2rml completed."  
fi

echo "---------------------------------"
echo "  Running RdfUpload..."
echo "---------------------------------"

# Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v $WORKING_DIRECTORY:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "$GRAPHDB_URL" \
  -rep "$GRAPHDB_REPOSITORY" \
  -un $GRAPHDB_USERNAME -pw $GRAPHDB_PASSWORD