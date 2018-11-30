SET working_directory="c:/data/data2services"

SET jdbc_url="jdbc:drill:drillbit=drill:31010"
:: SET jdbc_url="jdbc:postgresql://postgres:5432/my_database"

SET jdbc_container="drill"
:: SET jdbc_container="postgres"

SET jdbc_username="postgres"
SET jdbc_password="pwd"

ECHO %working_directory%


:: Generate RML mapping.ttl file. Be careful it needs to be in /data
::docker run -it --rm --link drill:drill -v %1:/data autor2rml -h drill -r -o /data/mapping.ttl %path%
docker run -it --rm --link %jdbc_container%:%jdbc_container% -v %working_directory%:/data autor2rml -j "%jdbc_url%" -r -o /data/mapping.ttl -d %working_directory% -u "%jdbc_username%" -p "%jdbc_password%" -b "http://data2services/" -g "http://data2services/graph/autor2rml"

:: TODO: add the config,properties file in the working_directory. Edit it if postgres
copy config.properties %working_directory%

:: Run r2rml to generate RDF files from TSV with the AutoDrill mappings
docker run -it --rm --link drill:drill -v %working_directory%:/data r2rml /data/config.properties

:: Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v %working_directory%:/data rdf-upload -m "HTTP" -if "/data" -url "http://graphdb:7200" -rep "test" -un import_user -pw test