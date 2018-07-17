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
docker run -it --rm --link drill:drill autodrill -h drill -r $DIRECTORY > $DIRECTORY/mapping.ttl

# Generate config.properties required for r2rml
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = /data/mapping.ttl
outputFile = /data/rdf_output.nq
format = NQUADS" > $DIRECTORY/config.properties

# Get it in Turtle format
#outputFile = /data/rdf_output.ttl.gz
#format = TURTLE" > $DIRECTORY/config.properties


# Run r2rml to generate RDF files
docker run -it --rm --link drill:drill -v $DIRECTORY:/data r2rml /data/config.properties

# Optional: Unzip generated RDF file
#gzip -d -k -f $DIRECTORY/rdf_output.ttl.gz

# Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v /data/pharmgkb_variants:/data rdf-upload \
  -m "HTTP" \
  -if "/data/rdf_output.nq" \
  -url "http://graphdb:7200" \
  -rep "test" \
  -un import_user -pw test

  #-m "RDF4JSPARQL" \
  #-if "/data/rdf_output.ttl.gz" \