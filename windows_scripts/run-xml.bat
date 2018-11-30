SET working_directory="/data/data2services"

ECHO %working_directory%

:: Run xml2rdf to generate RDF files from XML
docker run --rm -it -v /data:/data xml2rdf  -i "%working_directory%" -o "%working_directory%.nq.gz" -g "http://data2services/graph/xml2rdf"

:: Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v %working_directory%:/data rdf-upload -m "HTTP" -if "/data" -url "http://graphdb:7200" -rep "test" -un import_user -pw test