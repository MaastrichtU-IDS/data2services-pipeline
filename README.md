# Data 2 Services pipeline
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

# Or pull the submodule after a normal git clone
git submodule update --init --recursive
```

### Build

Downloads the files and builds the docker containers if required.

```shell
./build.sh
```

### Run

The directory where are the files to convert needs to be in `/data` (to comply with Apache Drill path).

The script starts GraphDB and Apache Drill services on Docker. They can be started manually with `resources/startup.sh` and stopped with `shutdown.sh`.

```shell
# All parameters
./run.sh --working-directory /data/data2services \
	--jdbc-url jdbc:drill:drillbit=drill:31010 \
	--jdbc-container drill \
	--jdbc-username postgres --jdbc-password pwd \
	--graphdb-url http://graphdb:7200/ \
	--graphdb-repository test \
	--graphdb-username import_user --graphdb-password test \
	--base-uri http://data2services/

# Parse XML using xml2rdf.
./run.sh --working-directory /data/my_file.xml
# Support compressed files.
./run.sh --working-directory /data/my_file.xml.gz

# Parse tabular files using Apache Drill
./run.sh --working-directory /data/data2services --jdbc-url "jdbc:drill:drillbit=drill:31010" --jdbc-container drill

# Postgres
./run.sh --working-directory /data/data2services --jdbc-url "jdbc:postgresql://postgres:5432/my_database" --jdbc-container postgres --jdbc-username postgres --jdbc-password pwd
```



### Transform generic RDF to target model

https://github.com/vemonet/insert-data2services



### Drill and GraphDb for Development

In a production environment it is considered that both Drill and GraphDb services are present. Other RDF stores should also work, but have not been tested yet.

```shell
# Start
./startup.sh
# Stop
./shutdown.sh
```

### 

## Windows

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

Be careful the AntiVirus might cause problems, you might need to deactivate it

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
