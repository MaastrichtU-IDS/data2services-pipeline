#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately

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
                        exit 0
                        ;;
                -f)
                        shift
                        if test $# -gt 0; then
                                export DIRECTORY=$1
                        else
                                echo "No file directory specified. Should point to a directory thats contains tsv, csv and/or psv data files to convert"
                                exit 1
                        fi
                        shift
                        ;;
                --file-directory*)
                        export DIRECTORY=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -rep)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB_REPOSITORY=$1
                        fi
                        shift
                        ;;
                --graphdb-repository*)
                        export GRAPHDB_REPOSITORY=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -fo)
                        shift
                        if test $# -gt 0; then
                                export RDF_FORMAT=$1
                        fi
                        shift
                        ;;
                --format*)
                        export RDF_FORMAT=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -u)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB_USERNAME=$1
                        fi
                        shift
                        ;;
                --username*)
                        export GRAPHDB_USERNAME=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -pw)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB_PASSWORD=$1
                        fi
                        shift
                        ;;
                --password*)
                        export GRAPHDB_PASSWORD=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
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


# Run AutoDrill to generate mapping file
docker run -it --rm --link drill:drill autodrill -h drill -r $DIRECTORY > $DIRECTORY/mapping.ttl

# Generate config.properties required for r2rml
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = /data/mapping.ttl
outputFile = /data/rdf_output.$OUTPUT_EXTENSION
format = $RDF_FORMAT" > $DIRECTORY/config.properties

# Run r2rml to generate RDF files
docker run -it --rm --link drill:drill -v $DIRECTORY:/data r2rml /data/config.properties

# Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v $DIRECTORY:/data rdf-upload \
  -m "HTTP" \
  -if "/data/rdf_output.$OUTPUT_EXTENSION" \
  -url "http://graphdb:7200" \
  -rep "$GRAPHDB_REPOSITORY" \
  -un $GRAPHDB_USERNAME -pw $GRAPHDB_PASSWORD