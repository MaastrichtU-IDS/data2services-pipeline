                                                     
# reactome JSON API file and SQL database files

docker run -it --rm -v /data/emonet/ncats/reactome:/data data2services-download --download-datasets reactome



docker run -it --rm -v /data/data2services:/data data2services-download --download-datasets reactome

docker run -it -v /data/data2services/reactome:/data json2xml -i /data

docker run -it -v /data/data2services/reactome:/data xml2rdf -i /data  -o /data/output_reactome.nq -g https://w3id.org/data2services/graph/xml2rdf/reactome 

docker run -it -v /data/data2services/reactome:/data xml2rdf -i /data/drugpairReactionCounts_1.xml  -o /data/drugpairReactionCounts_1.nq -g https://w3id.org/data2services/graph/xml2rdf/reactome 
# -n http://ids.unimaas.nl/xml2rdf/data/

for file in /data/data2services/reactome/*.xml; do docker run -it -v /data:/data xml2rdf -i $file -o $file.nq -g https://w3id.org/data2services/graph/xml2rdf/reactome ; done 

scp *.nq ids2:/home/emonet/reactome

# Load RDF file in GraphDB ncats-test repository

docker run -d --name convert_reactome --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/reactome" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/reactome outputGraph:https://w3id.org/data2services/graph/biolink/reactome

# Compute HCLS stats
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/reactome
