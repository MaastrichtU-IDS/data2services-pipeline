                                                     
# omim.tsv file in /data/data2services

docker run -it --rm -v /data/emonet/ncats/omim:/data data2services-download --download-datasets omim

docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill

docker run -it --rm --link drill:drill -v /data:/data autor2rml \
        -j "jdbc:drill:drillbit=drill:31010" -r \
        -o "/data/data2services/omim/mapping.trig" \
        -d "/data/data2services/omim" \
        -b "https://w3id.org/data2services/" \
        -g "https://w3id.org/data2services/graph/autor2rml/omim"

docker run -it --rm --link drill:drill \
  -v /data/data2services/omim:/data \
  r2rml /data/config.properties

# Load RDF file in GraphDB ncats-test repository

docker run -d --name convert_omim --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/omim" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/omim outputGraph:https://w3id.org/data2services/graph/biolink/omim
# 3s

docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/omim

#docker run -d --link graphdb:graphdb -v "/home/emonet/data2services-insert/compute-hcls-stats":/data data2services-sparql-operations -f "/data" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/omim


docker run -d --name convert_omim data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/omim" -ep "http://graphdb.dumontierlab.com/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/omim outputGraph:https://w3id.org/data2services/graph/biolink/omim


docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/omim