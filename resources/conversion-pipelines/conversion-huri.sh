                                                     
# HuRI.tsv file in /data/data2services

docker run -it --rm -v /data/emonet/ncats/huri:/data data2services-download --download-datasets huri

docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill

docker run -it --rm --link drill:drill -v /data:/data autor2rml \
        -j "jdbc:drill:drillbit=drill:31010" -r \
        -o "/data/emonet/ncats/huri/mapping.trig" \
        -d "/data/emonet/ncats/huri" \
        -b "https://w3id.org/data2services/" \
        -g "https://w3id.org/data2services/graph/autor2rml/huri"

docker run -it --rm --link drill:drill \
  -v /data/data2services:/data \
  r2rml /data/config.properties

# Load RDF file in GraphDB ncats-test repository

docker run -d --name convert_huri --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/huri" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/huri outputGraph:https://w3id.org/data2services/graph/biolink/huri
# 3s

docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/huri

#docker run -d --link graphdb:graphdb -v "/home/emonet/data2services-insert/compute-hcls-stats":/data data2services-sparql-operations -f "/data" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/huri


docker run -d --name convert_huri data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/huri" -ep "http://graphdb.dumontierlab.com/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/huri outputGraph:https://w3id.org/data2services/graph/biolink/huri


docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/huri