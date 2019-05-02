                                                     
# UniProt from https://sparql.uniprot.org/

docker run -it --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/insert-biolink/uniprot" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var outputGraph:https://w3id.org/data2services/graph/biolink/uniprot

# Only human
docker run -it --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/insert-biolink/uniprot" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var outputGraph:https://w3id.org/data2services/graph/biolink/uniprot/human


docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/uniprot
