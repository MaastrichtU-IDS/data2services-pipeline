## COHD SQL database (loaded in MariaDB on node2)

# Start MariaDB
docker run --rm --name cohd-mariadb -v /data:/data -e MYSQL_ROOT_PASSWORD=pwd -d mariadb

# Connect to MySQL
docker exec -it cohd-mariadb mysql -uroot -ppwd

# AutoR2RML
docker run -it --rm --link cohd-mariadb:cohd-mariadb -v /data/emonet/ncats/cohd/convert:/data autor2rml \
        -j "jdbc:mariadb://cohd-mariadb:3306/cohd?user=root&password=pwd" -r \
        -o "/data/mapping.trig" \
        -d "/data" \
        -b "https://w3id.org/data2services/" \
        -g "https://w3id.org/data2services/graph/autor2rml/cohd"

# R2RML
docker run -d --rm --link cohd-mariadb:cohd-mariadb \
  -v /data/emonet/ncats/cohd/convert:/data \
  r2rml /data/config.properties
# sharp_ramanujan


# Load RDF file in GraphDB ncats-test repository
docker run -d --name convert_cohd --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/insert-biolink/cohd" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/cohd outputGraph:https://w3id.org/data2services/graph/biolink/cohd

# Compute HCLS stats
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-insert/tree/master/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/cohd
