                                                     
# eggnog.tsv file in /data/data2services

docker run -it --rm -v /data/emonet/ncats/eggnog:/data data2services-download --download-datasets eggnog

docker run -dit --rm -p 8047:8047 -p 31010:31010 --name drill -v /data:/data:ro apache-drill

docker run -it --rm --link drill:drill -v /data:/data autor2rml \
        -j "jdbc:drill:drillbit=drill:31010" -r \
        -o "/data/emonet/ncats/eggnog/mapping.trig" \
        -d "/data/emonet/ncats/eggnog" \
        -b "https://w3id.org/data2services/" \
        -g "https://w3id.org/data2services/graph/autor2rml/eggnog"

docker run -it --rm --link drill:drill \
  -v /data/data2services:/data \
  r2rml /data/config.properties

# Load RDF file in GraphDB ncats-test repository

# Split Pmids:
docker run -d --name split-eggnog --link graphdb:graphdb \
  vemonet/data2services-sparql-operations -op split \
  --split-property "https://w3id.org/data2services/autor2rml/model/Pmids" \
  --split-delimiter ";" \
  -ep "http://graphdb:7200/repositories/ncats-test" \
  -uep "http://graphdb:7200/repositories/ncats-test/statements" \
  -un emonet -pw PASSWORD

docker run -d --name convert_eggnog --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/eggnog" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/eggnog outputGraph:https://w3id.org/data2services/graph/biolink/eggnog
# 3s

docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/eggnog

#docker run -d --link graphdb:graphdb -v "/home/emonet/data2services-insert/compute-hcls-stats":/data data2services-sparql-operations -f "/data" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/eggnog


docker run -d --name convert_eggnog data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/eggnog" -ep "http://graphdb.dumontierlab.com/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/eggnog outputGraph:https://w3id.org/data2services/graph/biolink/eggnog


docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/eggnog