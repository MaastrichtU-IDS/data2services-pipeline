SET working_path="c:/data/data2services"

ECHO %working_path%

:: Run xml2rdf to generate RDF files from XML
docker run --rm -it -v /data:/data xml2rdf  -i "%working_path%" -o "%working_path%.nq.gz" -g "http://data2services/graph/xml2rdf"

:: Run RdfUpload to upload to GraphDB
docker run -it --rm --link graphdb:graphdb -v %working_path%:/data rdf-upload -m "HTTP" -if "/data" -url "http://graphdb:7200" -rep "test" -un import_user -pw test