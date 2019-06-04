                                                     
# pathwaycommons JSON API file and SQL database files

docker run -it --rm -v /data/emonet/pathwaycommons:/data data2services-download --download-datasets pathwaycommons


# Load RDF file in GraphDB ncats-test repository

docker run -d --name convert_pathwaycommons --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/insert-biolink/biopax-pathwaycommons" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/pathwaycommons outputGraph:https://w3id.org/data2services/graph/biolink/pathwaycommons

# Compute HCLS stats
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/pathwaycommons
