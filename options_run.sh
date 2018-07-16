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
                        echo "-d, --directory=/data/pharmgkb       specify a working directory with tsv, csv and/or psv data files to convert"
                        echo "-gr, --graphdb-repository=test      specify a GraphDB repository. Default: test"
                        exit 0
                        ;;
                -d)
                        shift
                        if test $# -gt 0; then
                                export DIRECTORY=$1
                        else
                                echo "No working directory specified. Should contain the file tsv, csv and/or psv data files to convert"
                                exit 1
                        fi
                        shift
                        ;;
                --directory*)
                        export DIRECTORY=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -gr)
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
                *)
                        break
                        ;;
        esac
done

# Set default values
# If starts with / then it is an absolute path. We add /data to relative path for convenience
if  [[ $DIRECTORY == /* ]] ;
then
  echo "Using absolute path"
else
  DIRECTORY=/data/$DIRECTORY
fi
GRAPHDB_REPOSITORY=${GRAPHDB_REPOSITORY:-test}


echo "[-d] Working directory: $DIRECTORY"
echo "[-gr] GraphDB repository: $GRAPHDB_REPOSITORY"


# Run AutoDrill to generate mapping file
docker run -it --rm --link drill:drill autodrill -h drill -r $DIRECTORY > $DIRECTORY/mappings.ttl

# Generate config.properties
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = $DIRECTORY/mappings.ttl
outputFile = $DIRECTORY/rdf_output.ttl.gz
format = TTL" >> $DIRECTORY/config.properties

# Run r2rml to generate RDF files
#FIX: docker run -it --rm --link drill:drill -v $DIRECTORY:/data r2rml /data/config.properties SHOULD WORK
docker run -it --rm --link drill:drill -v /data:/data r2rml $DIRECTORY/config.properties

# Unzip generated RDF file
gzip -d -k -f $DIRECTORY/rdf_output.ttl.gz

# Run RdfUpload to upload to GraphDB
docker run -it -v $DIRECTORY:/data rdf-upload \
  -if "/data/rdf_output.ttl" \
  -url "http://graphdb:7200" \
  -rep "$GRAPHDB_REPOSITORY" \
  -un import_user -pw test