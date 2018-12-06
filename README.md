# Data 2 Services pipeline

Hackathon Google doc: https://docs.google.com/document/d/1DXcpH559jEGrMTSYr3rJ6el7j64mqtrz2f5gcqnE6nE/edit# 

This is a demonstrator ETL pipeline that converts relational databases, tabular files, and XML files into a generic RDF-format based on the input data structure, and loads it into a GraphDB endpoint. 

[Docker](https://docs.docker.com/install/) is required to run the pipeline.

## Linux

### Clone

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

### Build

Downloads the files and builds the docker containers if required.

```shell
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

For MacOS make sure the `/data` repository is access has been granted 

### Run

The directory where are the files to convert needs to be in `/data` (to comply with Apache Drill path).

The script starts GraphDB and Apache Drill services on Docker. They can be started manually with `resources/startup.sh` and stopped with `shutdown.sh`.

```shell
# All parameters
./run.sh --working-path /data/data2services \
	--jdbc-url jdbc:drill:drillbit=drill:31010 \
	--jdbc-container drill \
	--jdbc-username postgres --jdbc-password pwd \
	--graphdb-url http://graphdb:7200/ \
	--graphdb-repository test \
	--graphdb-username import_user --graphdb-password test \
	--base-uri http://data2services/

# Parse XML using xml2rdf.
./run.sh --working-path /data/my_file.xml
# Support GZ compressed file.
./run.sh --working-path /data/my_file.xml.gz

# Parse tabular files using Apache Drill
./run.sh --working-path /data/data2services --jdbc-url "jdbc:drill:drillbit=drill:31010" --jdbc-container drill

# Postgres
./run.sh --working-path /data/data2services --jdbc-url "jdbc:postgresql://postgres:5432/my_database" --jdbc-container postgres --jdbc-username postgres --jdbc-password pwd
```



### Transform generic RDF to target model

https://github.com/vemonet/insert-data2services



## Run Docker commands

### xml2rdf

```shell
docker run --rm -it -v /data:/data xml2rdf  -i "/data/data2services/myfile.xml.gz" -o "/data/data2services/myfile.nq.gz" -g "http://data2services/graph/xml2rdf"

docker run -it --rm --link graphdb:graphdb -v /data/data2services:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "http://graphdb:7200" \
  -rep "test" \
  -un "import_user" -pw "test"
```

### R2RML

First run AutoR2RML to generate the R2RML mapping file

```shell
# Apache Drill for CSV files
docker run -it --rm --link drill:drill -v /data:/data autor2rml \
	-j "jdbc:drill:drillbit=drill:31010" -r \
	-o "/data/data2services/mapping.ttl" \
	-d "/data/data2services" \
	-b "http://data2services/" -g "http://data2services/graph/autor2rml"
	
# Postgres
#jdbc:postgresql://localhost:5432/database

# SQLite
docker run -it --rm -v /data:/data autor2rml \
	-j "jdbc:sqlite:/data/sqlite/my_database.db" -r \
	-o "/data/sqlite/mapping.ttl" \
	-b "http://data2services/" -g "http://data2services/graph/sqlite"
```

Generate RDF from R2RML

```shell
# Generate R2RML config file
echo "connectionURL = jdbc:drill:drillbit=drill:31010
  mappingFile = /data/mapping.ttl
  outputFile = /data/rdf_output.nq
  format = NQUADS" > /data/data2services/config.properties

# R2RML
docker run -it --rm --link drill:drill -v /data/data2services:/data r2rml /data/config.properties

# RDF Upload
docker run -it --rm --link graphdb:graphdb -v /data/data2services:/data rdf-upload \
  -m "HTTP" \
  -if "/data" \
  -url "http://graphdb:7200" \
  -rep "test" \
  -un "import_user" -pw "test"
```





## Windows

Be careful if Docker can't access internet when building you might want to change the Network > DNS Server > Fixed: 8.8.8.8

Be careful the AntiVirus might cause problems, you might need to deactivate it

All windows scripts are in directory `windows_scripts`

```powershell
dir windows_scripts
```

### Build

* Download GraphDB and put it in the graphdb directory

  http://go.pardot.com/e/45622/38-graphdb-free-8-6-0-dist-zip/5pyc3s/1295914437

* Download Apache Drill and put it in the apache-drill directory

  [ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz](ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz)

* Build the images

```shell
./build.bat

# Create graphdb and graphdb-import directories in /data
mkdir /data/graphdb
mkdir /data/graphdb-import
```

* Create "test" repository by accessing http://localhost:7200/repository

### Drill and GraphDb for Development

In a production environment it is considered that both Drill and GraphDb services are present. Other RDF stores should also work, but have not been tested yet.
```shell
# Start
./startup.bat
# Stop
./shutdown.bat
```
### Run

```shell
# Run xml2rdf for XML files. Edit the script
./run-xml.bat

# Run AutoR2RML for Tabular files and RDB. Edit the script
./run-r2rml.bat

# Example running Drill
docker run -it --rm --link drill:drill -v c:/data/pharmgkb:/data autor2rml -h drill -r -o /data/mapping.ttl /data/pharmgkb
```



## Run Postgres

```shell
# Run and load Postgres DB to test
docker run --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=pwd -d -v /data/autor2rml/:/data postgres
docker exec -it postgres bash
su postgres
psql drugcentral < /data/drugcentral.dump.08262018.sql
```



## Fix tabular files without columns

```shell
# CSV
sed -i '1s/^/column1,column2,column3\n/' *.csv

# TSV
sed -i '1s/^/column1\tcolumn2\tcolumn3\n/' *.tsv
```





## Secure GraphDB: create users

- Start graphdb

  ```shell
  # On Linux
  ./startup.sh
  # On Windows
  ./startup.bat
  ```

- Go to http://localhost:7200/

- Setup > Repositories > Create new repository

  - Repository ID: **test** (or whatever you want it to be, but you will need to change data2services default config)
  - Check `Use context index`
  - Create

- Setup > Users and access

  - Edit admin user > Enter a new password > Save
  - Click on `Security is off` 
  - Create new user
    - User name: import_user
    - Password: test
    - Repository rights > Write right on `Any data repository`
    - Click `Create`



## Citing this work

If you use data2services in a scientific publication, you are highly encouraged (not required) to cite the following paper:

Data2Services: enabling automated conversion of data to services. Vincent Emonet, Alexander Malic, Amrapali Zaveri, Andreea Grigoriu and Michel Dumontier.

Bibtex entry:

```tex
@inproceedings{Emonet2018,
author = {Emonet, Vincent and Malic, Alexander and Zaveri, Amrapali and Grigoriu, Andreea and Dumontier, Michel},
title = {Data2Services: enabling automated conversion of data to services},
booktitle = {11th Semantic Web Applications and Tools for Healthcare and Life Sciences},
year = {2018}
}
```
