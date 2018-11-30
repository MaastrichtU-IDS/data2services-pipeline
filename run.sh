#!/bin/bash

#YAML_PATH=$1

# Parse commandline
echo "---------------------------------"
echo "  Commandline configuration:"
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -d|--working-directory)
    WORKING_DIRECTORY="$2"
    shift # past argument
    shift # past value
    ;;
    -j|--jdbc-url)
    JDBC_URL="$2"
    shift # past argument
    shift # past value
    ;;
    -ju|--jdbc-username)
    JDBC_USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -jp|--jdbc-password)
    JDBC_PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    -jc|--jdbc-container)
    JDBC_CONTAINER="$2"
    shift # past argument
    shift # past value
    ;;
    -gurl|--graphdb-url)
    GRAPHDB_URL="$2"
    shift # past argument
    shift # past value
    ;;
    -gurl|--graphdb-url)
    GRAPHDB_URL="$2"
    shift # past argument
    shift # past value
    ;;
    -gu|--graphdb-username)
    GRAPHDB_USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -gp|--graphdb-password)
    GRAPHDB_PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    -uri|--base-uri)
    BASE_URI="$2"
    shift # past argument
    shift # past value
    ;;
    #--default)
    #DEFAULT=YES
    #shift # past argument
    #;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Set default values
GRAPHDB_URL=${GRAPHDB_URL:-http://graphdb:7200}
GRAPHDB_REPOSITORY=${GRAPHDB_REPOSITORY:-test}
GRAPHDB_USERNAME=${GRAPHDB_USERNAME:-import_user}
GRAPHDB_PASSWORD=${GRAPHDB_PASSWORD:-test}
BASE_URI=${BASE_URI:-http://data2services/}


echo "--working-directory = $WORKING_DIRECTORY"
echo "--jdbc-url = $JDBC_URL"
echo "--jdbc-container for AutoR2RML = $JDBC_CONTAINER"
echo "--jdbc-username for AutoR2RML = $JDBC_USERNAME"
echo "--jdbc-password for AutoR2RML = $JDBC_PASSWORD"
echo "--graphdb-url = $GRAPHDB_URL"
echo "--graphdb-repository = $GRAPHDB_REPOSITORY"
echo "--graphdb-username = $GRAPHDB_USERNAME"
echo "--graphdb-password = $GRAPHDB_PASSWORD"
echo "--base-uri = $BASE_URI"

INPUT_PATH=$WORKING_DIRECTORY

# Start Apache Drill if not running
if [ ! "$(docker ps -q -f name=drill)" ]; then
    docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill
fi

# Start GraphDB if not running
if [ ! "$(docker ps -q -f name=graphdb)" ]; then
    docker run -d --rm --name graphdb -p 7200:7200 -v /data/graphdb:/opt/graphdb/home -v /data/graphdb-import:/root/graphdb-import graphdb
    sleep 20
fi



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
  echo "Running AutoR2RML to generate R2RML mapping files..."

  # TODO: WARNING the $WORKING_DIRECTORY passed at the end is the path INSIDE the Apache Drill docker container (it must always starts with /data).
  # So this script only works with dir inside /data)
  docker run -it --rm --link $JDBC_CONTAINER:$JDBC_CONTAINER -v $WORKING_DIRECTORY:/data autor2rml -j "$JDBC_URL" -r -o /data/mapping.ttl -d "$WORKING_DIRECTORY" -u "$JDBC_USERNAME" -p "$JDBC_PASSWORD" -b "$BASE_URI" -g "http://data2services/graph/autor2rml"

  echo "R2RML mappings (mapping.ttl) has been generated. Running r2rml..."

  ## Generate config.properties required for r2rml. TODO: Should we generate this directly in AutoR2RML? Alex: no
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

# Create GraphDB repository
curl -X PUT --header 'Content-Type: application/json' --header 'Accept: */*' -d "{
  \"id\": \"$GRAPHDB_REPOSITORY\",
  \"location\": \"\",
  \"params\": {},
  \"sesameType\": \"graphdb:FreeSailRepository\",
  \"title\": \"\",
  \"type\": \"free\"
 }" "$GRAPHDB_URL/rest/repositories"

# Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v $WORKING_DIRECTORY:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "$GRAPHDB_URL" \
  -rep "$GRAPHDB_REPOSITORY" \
  -un $GRAPHDB_USERNAME -pw $GRAPHDB_PASSWORD
