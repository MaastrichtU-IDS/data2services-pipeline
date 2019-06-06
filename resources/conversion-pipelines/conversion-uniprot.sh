                                                     
# UniProt from https://sparql.uniprot.org/

docker run -it --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/uniprot" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var outputGraph:https://w3id.org/data2services/graph/biolink/uniprot

# Only human
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/uniprot" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var outputGraph:https://w3id.org/data2services/graph/biolink/uniprot/human
#44cad421d7bcac15ea03d9940d9488aa7855a5995d62d70fdd85c553144d2e5c
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/uniprot" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var outputGraph:https://w3id.org/data2services/graph/biolink/uniprot
#1d84a4fcb4ba4394d7a847f7e0ac9a1e3aed4f29b36c70d06519ce850c86ec02

# Compute HCLS
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/uniprot/human
# 91dcff9e5d9d70c98e423bf87577f4fcb2393f0e6fb16d35cb74e2fd2c48c026
