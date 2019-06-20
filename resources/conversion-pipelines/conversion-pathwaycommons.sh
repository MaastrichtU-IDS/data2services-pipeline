                                                     
# pathwaycommons JSON API file and SQL database files

docker run -it --rm -v /data/emonet/pathwaycommons:/data data2services-download --download-datasets pathwaycommons


# Load RDF file in GraphDB ncats-test repository

#docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/biopax-pathwaycommons" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:http://pathwaycommons.org/pc2/graph outputGraph:https://w3id.org/data2services/graph/biolink/pathwaycommons
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/biopax-pathwaycommons" -ep "http://graphdb:7200/repositories/test-vincent/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:http://pathwaycommons.org/pc2/graph outputGraph:https://w3id.org/data2services/graph/biolink/pathwaycommons
# fd445012a07f71a00bbd17709116f91e4808e31bb79e3e251ae5a168a015e95b

# Compute HCLS stats
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/pathwaycommons

docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/test-vincent/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/pathwaycommons
# 24ff373de83775b3798dc95dc0771ca81a31f812343efb6a18a94a47891e3c25