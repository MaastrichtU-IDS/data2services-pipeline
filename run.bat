SETLOCAL ENABLEDELAYEDEXPANSION
SET search=c:/
SET replace=/
SET path=!1:%search%=%replace%!
ECHO %path%

:: Generate RML mapping.ttl file
docker run -it --rm --link drill:drill -v %1:/data autor2rml -h drill -r -o /data/mapping.ttl %path%

:: Run r2rml to generate RDF files from TSV with the AutoDrill mappings
docker run -it --rm --link drill:drill -v %1:/data r2rml /config.properties

:: Run xml2rdf to generate RDF files from XML
docker run --rm -it -v %1:/data/ xml2rdf "/data"

:: Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v %1:/data rdf-upload -m "HTTP" -if "/data" -url "http://graphdb:7200" -rep "test" -un import_user -pw test