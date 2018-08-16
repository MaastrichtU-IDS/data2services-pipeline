#!/bin/bash

# Get commandline options
while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "$package - attempt to capture frames"
                        echo " "
                        echo "$package [options] application [arguments]"
                        echo " "
                        echo "options:"
                        echo "-h, --help                show brief help"
                        echo "-f, --file-directory=/data/file_repository       specify a working directory with tsv, csv and/or psv data files to convert"
                        echo "-gr, --graphdb-repository=test      specify a GraphDB repository. Default: test"
                        echo "-fo, --format=nquads      Specify a format for RDF out when running r2rml. Default: nquads"
                        echo "-un, --username=import_user      Specify a format for RDF out when running r2rml. Default: import_user"
                        echo "-pw, --password=test      Specify a format for RDF out when running r2rml. Default: import_user"
                        exit 0;;
                -f)
                        shift
                        if test $# -gt 0; then
                                export DIRECTORY=$1
                        else
                                echo "No file directory specified. Should point to a directory thats contains tsv, csv and/or psv data files to convert"
                                exit 1
                        fi
                        shift;;
                --file-directory*)
                        export DIRECTORY=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift;;
                -rep)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB_REPOSITORY=$1
                        fi
                        shift;;
                --graphdb-repository*)
                        export GRAPHDB_REPOSITORY=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift;;
                -fo)
                        shift
                        if test $# -gt 0; then
                                export RDF_FORMAT=$1
                        fi
                        shift;;
                --format*)
                        export RDF_FORMAT=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift;;
                -u)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB_USERNAME=$1
                        fi
                        shift;;
                --username*)
                        export GRAPHDB_USERNAME=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift;;
                -pw)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB_PASSWORD=$1
                        fi
                        shift;;
                --password*)
                        export GRAPHDB_PASSWORD=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift;;
                *)
                        break;;
        esac
done

# Set default values
GRAPHDB_REPOSITORY=${GRAPHDB_REPOSITORY:-test}
GRAPHDB_USERNAME=${GRAPHDB_USERNAME:-import_user}
GRAPHDB_PASSWORD=${GRAPHDB_PASSWORD:-test}

# If directory starts with / then it is an absolute path. We add /data to relative path for convenience
if  [[ $DIRECTORY == /* ]] ;
then
  echo "Using absolute path"
else
  DIRECTORY=/data/$DIRECTORY
fi

# If the user ask for the turtle format we provide it, otherwise its nquads to get the Graph
if  [[ "$RDF_FORMAT" == "TURTLE" ]] || [[ "$RDF_FORMAT" == "TTL" ]];
then
  OUTPUT_EXTENSION="ttl.gz"
  RDF_FORMAT="TURTLE"
else
  OUTPUT_EXTENSION="nq"
  RDF_FORMAT="NQUADS"
fi

echo "[-f] Working file directory: $DIRECTORY"
echo "[-fo] RDF format: $RDF_FORMAT"
echo "[-rep] GraphDB repository: $GRAPHDB_REPOSITORY"
echo "[-un] GraphDB username: $GRAPHDB_USERNAME"
echo "[-pw] GraphDB password: $GRAPHDB_PASSWORD"


echo "---------------------------------"
echo "Running AutoDrill..."
echo "---------------------------------"

# Run AutoDrill to generate mapping file
# TODO: WARNING the $DIRECTORY passed at the end is the path INSIDE the Apache Drill docker container (it must always starts with /data).
# So this script only works with dir inside /data)
docker run -it --rm --link drill:drill -v $DIRECTORY:/data autodrill -h drill -r -o /data/mapping.ttl $DIRECTORY

echo "RML mappings (mapping.ttl) has been generated."


echo "---------------------------------"
echo "Running r2rml..."
echo "---------------------------------"

# Run r2rml to generate RDF files. Using config.properties at the root dir of the container
docker run -it --rm --link drill:drill -v $DIRECTORY:/data r2rml /config.properties

echo "r2rml completed."

# To run it with local config.properties:
#docker run -it --rm --link drill:drill -v /data/kraken-download/datasets/pharmgkb:/data r2rml /data/config.properties

echo "---------------------------------"
echo "Running xml2rdf..."
echo "---------------------------------"

docker run --rm -it -v $DIRECTORY:/data/ xml2rdf "/data"

# Works on Pubmed, 3G nt file: 
#docker run --rm -it -v /data:/data/ xml2rdf "/data/kraken-download/datasets/pubmed/baseline/pubmed18n0009.xml" "/data/kraken-download/datasets/pubmed/pubmed.nt.gz"
# Error, needs dtd apparently
#docker run --rm -it -v /data:/data/ xml2rdf "/data/kraken-download/datasets/interpro/interpro.xml" "/data/kraken-download/datasets/interpro/interpro.nt.gz"

echo "---------------------------------"
echo "Running RdfUpload..."
echo "---------------------------------"

# Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v $DIRECTORY:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "http://graphdb:7200" \
  -rep "$GRAPHDB_REPOSITORY" \
  -un $GRAPHDB_USERNAME -pw $GRAPHDB_PASSWORD