# data2services-pipeline

This is a demonstrator ETL pipeline that converts relational databases, tabular files, and XML files into a generic RDF-format based on the input data structure, and loads it into a GraphDB endpoint. 

[Docker](https://docs.docker.com/install/) is required to run the pipeline.

*Warning:* If Docker can't access internet when building you might want to change the DNS. E.g.: `wget: unable to resolve host address`

- On Linux: `vim /etc/resolv.conf` > `nameserver 8.8.8.8`
- On Windows: `Docker Settings > Network > DNS Server > Fixed: 8.8.8.8`

## Clone

```shell
# WARNING: fix newline bugs on Windows
git config --global core.autocrlf false
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-pipeline.git

cd data2services-pipeline

# Update submodules
git submodule update --recursive --remote
```

## Linux & MacOS

Windows documentation can be found [here](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Run-on-Windows).

### Build

Convenience script to build and pull all Docker images. You will **need to download** [Apache Drill installation bundle](https://drill.apache.org/download/) and [GraphDB standalone zip](https://www.ontotext.com/products/graphdb/) (register to get an email with download URL).

```shell
# Download Apache Drill
curl http://apache.40b.nl/drill/drill-1.15.0/apache-drill-1.15.0.tar.gz -o apache-drill/apache-drill-1.15.0.tar.gz
# Build docker images (don't forget to get GraphDB zip file)
./build.sh
```

### Start services

In a production environment it is considered that both **Apache Drill** and **GraphDB** services are present. Use `docker-compose` to start them. Other RDF stores should also work, but have not been tested yet.

```shell
# Start
docker-compose up -d
# Stop
docker-compose down
```

For MacOS, make sure that access to the `/data` repository has been granted in Docker configuration.

### Run using Docker commands

The directory where are the **files to convert needs to be in `/data`** (to comply with Apache Drill path).

Here examples with files in `/data/data2services`.

#### Convert XML

Use [xml2rdf](https://github.com/MaastrichtU-IDS/xml2rdf) to convert XML files to a generic RDF based on the file structure.

```shell
docker run --rm -it -v /data:/data xml2rdf  -i "/data/data2services/myfile.xml.gz" -o "/data/data2services/myfile.nq.gz" -g "http://data2services/graph/xml2rdf"

docker run -it --rm --link graphdb:graphdb -v /data/data2services:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "http://graphdb:7200" \
  -rep "test" \
  -un "import_user" -pw "test"
```

#### Convert TSV & RDB

##### AutoR2RML

Use [AutoR2RML](https://github.com/amalic/autor2rml) to convert relational databases (Postgres, SQLite), CSV, TSV and PSV files to a generic RDF 

First run AutoR2RML to generate the R2RML mapping file

```shell
# For CSV, TSV, PSV files
docker run -it --rm --link drill:drill -v /data:/data autor2rml \
	-j "jdbc:drill:drillbit=drill:31010" -r \
	-o "/data/data2services/mapping.trig" \
	-d "/data/data2services" \
	-b "http://data2services/" -g "http://data2services/graph/autor2rml"
	
# For Postgres
docker run -it --rm --link postgres:postgres -v /data:/data autor2rml \
	-j "jdbc:postgresql://postgres:5432/my_database" -r \
	-o "/data/data2services/mapping.trig" \
	-u "postgres" -p "pwd" \
	-b "http://data2services/" -g "http://data2services/graph/postgres"

# For MariaDB
docker run -it --rm --link mariadb:mariadb -v /data:/data autor2rml -j "jdbc:mariadb://mariadb:3306/my_database" -r -o "/data/data2services/mapping.trig" -u "root" -p "pwd" -b "http://data2services/" -g "http://data2services/graph/autor2rml"

# For SQLite
docker run -it --rm -v /data:/data autor2rml \
	-j "jdbc:sqlite:/data/data2services/my_database.db" -r \
	-o "/data/data2services/mapping.trig" \
	-b "http://data2services/" -g "http://data2services/graph/sqlite"
```

##### r2rml

Then generate RDF from [R2RML](https://github.com/amalic/r2rml). 

```shell
# config.properties file for R2RML in /data/data2services
connectionURL = jdbc:drill:drillbit=drill:31010
mappingFile = /data/mapping.trig
outputFile = /data/rdf_output.nq
format = NQUADS

# R2RML for Drill
docker run -it --rm --link drill:drill -v /data/data2services:/data r2rml /data/config.properties
# R2RML for Postgres
docker run -it --rm --link postgres:postgres -v /data/data2services:/data r2rml /data/config.properties
```

#### RdfUpload

Finally, upload the generated RDF. It can also be done manually using [GraphDB server imports](http://graphdb.ontotext.com/documentation/standard/loading-data-using-the-workbench.html#importing-server-files) for more efficiency on large files.

```shell
# RDF Upload
docker run -it --rm --link graphdb:graphdb -v /data/data2services:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "http://graphdb:7200" \
  -rep "test" \
  -un "import_user" -pw "PASSWORD"
```



## Transform generic RDF to target model

Next step is to transform the generic RDF generated a particular datamodel. See the [data2services-insert](https://github.com/MaastrichtU-IDS/data2services-insert) project for examples of transformation to the [BioLink model](https://biolink.github.io/biolink-model/docs/).

```shell
# Clone
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-insert
# Build
docker build -t rdf4j-sparql-operations rdf4j-sparql-operations
# Run
docker run -d -v "$PWD/data2services-insert/insert-biolink/drugbank":/data \
	rdf4j-sparql-operations -f "/data" -un USERNAME -pw PASSWORD \
	-ep "http://graphdb.dumontierlab.com/repositories/ncats-red-kg/statements" \
    -var serviceUrl:http://localhost:7200/repositories/test inputGraph:http://data2services/graph/xml2rdf/drugbank#5.1.1 outputGraph:https://w3id.org/data2services/graph/biolink/drugbank
```



## Download datasets

Source files can be set to be downloaded automatically using Shell scripts. See the [data2services-download](https://github.com/MaastrichtU-IDS/data2services-download) module for more details.

```shell
# Clone
git clone https://github.com/MaastrichtU-IDS/data2services-download.git
# Build
docker build -t data2services-download data2services-download
# Run
docker run -it --rm -v /data/data2services:/data data2services-download \
	--download-datasets aeolus,pharmgkb,ctd \
	--username my_login --password my_password \
	--clean # to delete all files in /data/data2services
```



## Further documentation in Wiki

* [Run on Windows](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Run-on-Windows)
* [Run using convenience scripts](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Run-using-convenience-script)
* [Run Postgres](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Run-PostgreSQL)
* [Run MariaDB](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Run-MariaDB)
* [Secure GraphDB](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Secure-GraphDB:-create-users)
* [Fix CSV, TSV, PSV files without columns](https://github.com/MaastrichtU-IDS/data2services-pipeline/wiki/Fix-CSV,-TSV,-PSV-files-without-columns)



## Citing this work

If you use data2services in a scientific publication, you are highly encouraged (not required) to cite the following paper:

**Data2Services: enabling automated conversion of data to services.** *Vincent Emonet, Alexander Malic, Amrapali Zaveri, Andreea Grigoriu and Michel Dumontier.*

Bibtex entry:

```tex
@inproceedings{Emonet2018,
author = {Emonet, Vincent and Malic, Alexander and Zaveri, Amrapali and Grigoriu, Andreea and Dumontier, Michel},
title = {Data2Services: enabling automated conversion of data to services},
booktitle = {11th Semantic Web Applications and Tools for Healthcare and Life Sciences},
year = {2018}
}
```

