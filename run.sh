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
    -p|--working-path)
    WORKING_PATH="$2"
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


echo "--working-directory = $WORKING_PATH (must be in a subfolder of /data)"
echo "--jdbc-url = $JDBC_URL"
echo "--jdbc-container for AutoR2RML = $JDBC_CONTAINER"
echo "--jdbc-username for AutoR2RML = $JDBC_USERNAME"
echo "--jdbc-password for AutoR2RML = $JDBC_PASSWORD"
echo "--graphdb-url = $GRAPHDB_URL"
echo "--graphdb-repository = $GRAPHDB_REPOSITORY"
echo "--graphdb-username = $GRAPHDB_USERNAME"
echo "--graphdb-password = $GRAPHDB_PASSWORD"
echo "--base-uri = $BASE_URI"

# Start Apache Drill if not running
if [ ! "$(docker ps -q -f name=drill)" ]; then
    docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill
fi

# Start GraphDB if not running
if [ ! "$(docker ps -q -f name=graphdb)" ]; then
    docker run -d --rm --name graphdb -p 7200:7200 -v /data/graphdb:/opt/graphdb/home -v /data/graphdb-import:/root/graphdb-import graphdb
    sleep 20
fi



if [[ $WORKING_PATH == *.xml || $WORKING_PATH == *.xml.gz ]]
then

  echo "---------------------------------"
  echo "  Running xml2rdf..."
  echo "---------------------------------"
  GRAPH_URI_FRAGMENT="graph/xml2rdf"

  docker run --rm -it -v /data:/data xml2rdf  -i "$WORKING_PATH" -o "$WORKING_PATH.nq.gz" -g "$BASE_URI$GRAPH_URI_FRAGMENT"
else

  echo "---------------------------------"
  echo "  Converting TSV to RDF..."
  echo "---------------------------------"
  echo "Running AutoR2RML to generate R2RML mapping files..."
  GRAPH_URI_FRAGMENT="graph/autor2rml"

  docker run -it --rm --link $JDBC_CONTAINER:$JDBC_CONTAINER -v /data:/data autor2rml -j "$JDBC_URL" -r -o /data/mapping.ttl -d "$WORKING_PATH" -u "$JDBC_USERNAME" -p "$JDBC_PASSWORD" -b "$BASE_URI" -g "$BASE_URI$GRAPH_URI_FRAGMENT"

  echo "R2RML mappings (mapping.ttl) has been generated. Running r2rml..."

  # Generate config.properties required for r2rml.
  sudo touch $WORKING_PATH/config.properties
  sudo chmod 777 $WORKING_PATH/config.properties
  echo "connectionURL = $JDBC_URL
  mappingFile = /data/mapping.ttl
  outputFile = /data/rdf_output.nq
  user = $JDBC_USERNAME
  password = $JDBC_PASSWORD
  format = NQUADS" > $WORKING_PATH/config.properties

  # Run r2rml to generate RDF files. Using config.properties at the root dir of the container
  docker run -it --rm --link $JDBC_CONTAINER:$JDBC_CONTAINER -v $WORKING_PATH:/data r2rml /data/config.properties

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
 }" "http://localhost:7200/rest/repositories"

# Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v $WORKING_PATH:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url $GRAPHDB_URL \
  -rep $GRAPHDB_REPOSITORY \
  -un $GRAPHDB_USERNAME -pw $GRAPHDB_PASSWORD
