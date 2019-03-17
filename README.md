# data2services-pipeline

This is a demonstrator ETL pipeline that converts relational databases, tabular files, and XML files into a generic RDF-format based on the input data structure, and loads it into a GraphDB endpoint. 

[Docker](https://docs.docker.com/install/) is required to run the pipeline.

*Warning:* If Docker can't access internet when building you might want to change the DNS. E.g.: `wget: unable to resolve host address`

- On Linux: `vim /etc/resolv.conf` > `nameserver 8.8.8.8`
- On Windows: `Docker Settings > Network > DNS Server > Fixed: 8.8.8.8`

## Clone

```shell
# WARNING: for Windows execute it before cloning to fix bugs with newlines
git config --global core.autocrlf false
# HTTPS
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-pipeline.git
# SSH
git clone --recursive git@github.com:MaastrichtU-IDS/data2services-pipeline.git

cd data2services-pipeline

# Or pull the submodule after a normal git clone
git submodule update --init --recursive
```

## Linux & MacOS

Windows documentation can be found [here](https://github.com/MaastrichtU-IDS/data2services-pipeline#windows).

### Build

Convenience script to build and pull all Docker images. You will **need to download** [Apache Drill installation bundle](https://drill.apache.org/download/) and [GraphDB standalone zip](https://www.ontotext.com/products/graphdb/) (register to get an email with download URL).

```shell
curl http://apache.40b.nl/drill/drill-1.15.0/apache-drill-1.15.0.tar.gz -o apache-drill/apache-drill-1.15.0.tar.gz
./build.sh
```

### Start services

In a production environment it is considered that both **Apache Drill** and **GraphDB** services are present. Other RDF stores should also work, but have not been tested yet.

```shell
# Start
./startup.sh
# Stop
./shutdown.sh
```

For MacOS, make sure that access to the `/data` repository has been granted in Docker configuration.

### Run

The directory where are the **files to convert needs to be in `/data`** (to comply with Apache Drill path).

Here examples with files in */data/data2services*.

#### Using Docker commands

##### Convert XML

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

##### Convert TSV & RDB

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

Then generate RDF from [R2RML](https://github.com/amalic/r2rml) and upload it

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

# RDF Upload
docker run -it --rm --link graphdb:graphdb -v /data/data2services:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "http://graphdb:7200" \
  -rep "test" \
  -un "import_user" -pw "test"
```

#### Using convenience script

```shell
# XML using xml2rdf.
./run.sh --working-path /data/data2services/my_file.xml --graph http://data2services/graph/xml2rdf
# Support GZ compressed file.
./run.sh --working-path /data/data2services/my_file.xml.gz --graph http://data2services/graph/xml2rdf


# Generate generic RDF from TSV, CSV, PSV files using Apache Drill
./run.sh --working-path /data/data2services --jdbc-url "jdbc:drill:drillbit=drill:31010" --jdbc-container drill --graph http://data2services/graph/autor2rml

# Generate generic RDF from Postgres
./run.sh --working-path /data/data2services --jdbc-url "jdbc:postgresql://postgres:5432/$MY_DATABASE" --jdbc-container postgres --jdbc-username postgres --jdbc-password pwd --graph http://data2services/graph/autor2rml


# With all parameters (if different GraphDB params)
./run.sh --working-path /data/data2services \
	--jdbc-url jdbc:drill:drillbit=drill:31010 \
	--jdbc-container drill \
	--jdbc-username postgres --jdbc-password pwd \
	--graphdb-url http://graphdb:7200/ \
	--graphdb-repository test \
	--graphdb-username import_user --graphdb-password test \
	--base-uri http://data2services/ --graph http://data2services/graph/generic
```

---

### Transform generic RDF to target model

https://github.com/MaastrichtU-IDS/data2services-insert

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

---

### Download datasets

https://github.com/MaastrichtU-IDS/data2services-download

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

---

## Windows

*Disclaimer:* the pipeline has not been test on Windows as extensively as on Linux, and Windows is not as stable so you might encounter some issues. Feel free to document them in [issues](https://github.com/MaastrichtU-IDS/data2services-pipeline/issues), especially if a you have found a solution.

All windows scripts are in the **`windows_scripts` folder** and designed to be run from this directory.

```powershell
cd windows_scripts
```

### Build

* Download GraphDB and put it in the graphdb directory

  http://go.pardot.com/e/45622/38-graphdb-free-8-6-0-dist-zip/5pyc3s/1295914437

* Download Apache Drill and put it in the apache-drill directory

  [ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz](ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz)

* Build the images

```shell
build.bat

# Create graphdb and graphdb-import directories in /data
mkdir /data/graphdb
mkdir /data/graphdb-import
```

### Drill and GraphDb for Development

In a production environment it is considered that both Drill and GraphDb services are present. Other RDF stores should also work, but have not been tested yet.
```shell
# Start
startup.bat
# Stop
shutdown.bat
```
Create "*test*" repository by accessing http://localhost:7200/repository

### Run

**Edit the bat files** to set your parameters. You can also manually [run the Docker commands](https://github.com/MaastrichtU-IDS/data2services-pipeline#using-docker-commands) for better control of the workflow.

```shell
# Run xml2rdf for XML files. Edit the script
run-xml.bat

# Run AutoR2RML for Tabular files and RDB. Edit the script
run-r2rml.bat
```



## Further documentation in Wiki

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

