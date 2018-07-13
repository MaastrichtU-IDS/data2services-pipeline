#!/bin/bash
set -e
# Any subsequent(*) commands which fail will cause the shell script to exit immediately


while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "$package - attempt to capture frames"
                        echo " "
                        echo "$package [options] application [arguments]"
                        echo " "
                        echo "options:"
                        echo "-h, --help                show brief help"
                        echo "-d, --directory=/data/pharmgkb_drugs       specify a working directory with tsv, csv and/or psv data files to convert"
                        echo "-dr, --drill=172.17.0.2      specify a host for drill. Default: 172.17.0.2"
                        echo "-db, --graphdb=172.17.0.3      specify a host for drill. Default: 172.17.0.3"
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
                -dh)
                        shift
                        if test $# -gt 0; then
                                export DRILL=$1
                        fi
                        shift
                        ;;
                --drill-host*)
                        export DRILL=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -db)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB=$1
                        fi
                        shift
                        ;;
                --graphdb*)
                        export GRAPHDB=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -gr)
                        shift
                        if test $# -gt 0; then
                                export GRAPHDB=$1
                        fi
                        shift
                        ;;
                --graph-repository*)
                        export GRAPHDB=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done

# If starts with / then it is an absolute path. We add /data to relative path for convenience
if  [[ $DIRECTORY == /* ]] ;
then
  echo "Mee"
else
  DIRECTORY=/data/$DIRECTORY
fi
DRILL=${DRILL:-172.17.0.2}
GRAPHDB=${GRAPHDB:-172.17.0.3}
GRAPH_REPOSITORY=${GRAPH_REPOSITORY:-kraken_test}

echo "[-d] Working directory: $DIRECTORY"
echo "[-dr] Drill: $DRILL"
echo "[-db] GraphDB host: $GRAPHDB"
echo "[-gr] GraphDB repository: $GRAPH_REPOSITORY"

: '
docker run -it --rm --link drill:drill autodrill -h $DRILL -r $DIRECTORY > $DIRECTORY/mappings.ttl

# Generate config.properties
echo "connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = $DIRECTORY/mappings.ttl
outputFile = $DIRECTORY/rdf_output.ttl.gz
format = TTL" >> $DIRECTORY/config.properties

# Run r2rml to generate RDF files
#Bug: docker run -it --rm --link drill:drill -v $DIRECTORY:/data r2rml /data/config.properties
docker run -it --rm --link drill:drill -v /data:/data r2rml $DIRECTORY/config.properties

# Unzip generated RDF file
gzip -d -k -f $DIRECTORY/rdf_output.ttl.gz
'

# Run RdfUpload to upload to GraphDB
docker run -it --rm -v $DIRECTORY:/data rdf-upload \
  -if "/data/rdf_output.ttl" \
  -ep "$GRAPHDB:7200/repositories/$GRAPH_REPOSITORY" \
  -uep "$GRAPHDB:7200/repositories/$GRAPH_REPOSITORY/statements" \
  -un admin -pw admin

: '
docker run -it --rm -v /data:/data rdf-upload \
  -if "/data/pharmgkb_drugs/rdf_output.ttl" \
  -ep "http://172.17.0.3:7200/repositories/kraken_test" \
  -uep "http://172.17.0.3:7200/repositories/kraken_test/statements" \
  -un admin -pw admin

WORKING:
docker run -it --rm -v /data:/data rdf-upload \
  -if "/data/rdfu/affymetrix_test.ttl" \
  -ep "http://172.17.0.3:7200/repositories/kraken_test" \
  -uep "http://172.17.0.3:7200/repositories/kraken_test/statements" \
  -un admin -pw admin
'
