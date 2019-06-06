## COHD SQL database (loaded in MariaDB on node2)

# Start MariaDB
docker run --rm --name cohd-mariadb -v /data:/data -e MYSQL_ROOT_PASSWORD=pwd -d mariadb

# Connect to MySQL
docker exec -it cohd-mariadb mysql -uroot -ppwd
\r cohd


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
# OutOfMemory Error: 2e2ef5cbd80323e6a2c7d3ffc334d45f9b0e40718701624bb344e6bef262d89b
# Without the big mapping: 4a509a1869a9fbd1721d6adb589aaffcafa74383ae7277895af2567158cfee72
# Run the big: 8ebc1320eadd4883c779c166320107d093e99614f2c50df5f28353da2f239a9b

# COHD tables size in MB:
# cohd               | concept_pair_counts                                |    1937.98 |
# cohd               | concept                                            |       7.55 |
# cohd               | concept_counts                                     |       1.88 |
select row_number() over () as autor2rml_rownum
         , concept_id_1
         , concept_id_2
         , concept_count
         , concept_frequency
       from concept_pair_counts;
# Without row number: 32788901 rows in set (54.859 sec)
#With row: 32788901 rows in set (2 min 15.783 sec)

# Load RDF file in GraphDB ncats-test repository
docker run -d --name convert_cohd --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/insert-biolink/cohd" -ep "http://graphdb:7200/repositories/ncats-red-kg/statements" -un emonet -pw $PASSWORD -var serviceUrl:http://localhost:7200/repositories/ncats-test inputGraph:https://w3id.org/data2services/graph/autor2rml/cohd outputGraph:https://w3id.org/data2services/graph/biolink/cohd

# Compute HCLS stats
docker run -d --link graphdb:graphdb data2services-sparql-operations -f "https://github.com/MaastrichtU-IDS/data2services-transform-repository/tree/master/sparql/compute-hcls-stats" -ep "http://graphdb:7200/repositories/bio2vec/statements" -un emonet -pw $PASSWORD -var inputGraph:https://w3id.org/data2services/graph/biolink/cohd
