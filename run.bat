
SETLOCAL ENABLEDELAYEDEXPANSION
SET search=c:/
SET replace=/
SET path=!1:%search%=%replace%!
ECHO %path%


:: Generate RML mapping.ttl file
docker run -it --rm --link drill:drill -v %1:/data autodrill -h drill -r -o /data/mapping.ttl %path%
:: Generate config.properties required for r2rml
echo connectionURL = jdbc:drill:drillbit=drill:31010 > %1/config.properties
echo mappingFile = /data/mapping.ttl >> %1/config.properties
echo outputFile = /data/rdf_output.nq >> %1/config.properties
echo format = NQUADS >> %1/config.properties
:: Run r2rml to generate RDF files
docker run -it --rm --link drill:drill -v %1:/data r2rml /data/config.properties
:: Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v %1:/data rdf-upload -m "HTTP" -if "/data/rdf_output.nq" -url "http://graphdb:7200" -rep "test" -un import_user -pw test