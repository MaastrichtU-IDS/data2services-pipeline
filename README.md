# Data 2 Services pipeline
This is a demonstrator ETL pipeline that converts PharmGKB data into a generic RDF-format and loads it into a GraphDb endpoint. 

After the enpoint is started up, a repository called "test", and a user called "import_user" (password "test") with write permissons to the test repository need to be configured. Also security has to be enabled.

This pipeline has been tested with PharmGKB (located in /data/pharmgkb) and HGNC data on both Linux and Mac OS-X running the latest Docker-CE version. This pipeline should also work on Windows. Paths from "/data" need to be changed to "c:/data".

## Clone

```shell
# WARNING: for Windows execute it before cloning to fix bugs with newlines
git config --global core.autocrlf false

# HTTPS
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-pipeline.git

# SSH
git clone --recursive git@github.com:MaastrichtU-IDS/data2services-pipeline.git
```

## Build
Downloads the files and builds the docker containers if required.
```shell
## On Linux
./build.sh

## On Windows
# Download GraphDB and Apache Drill
cd graphdb
wget -O graphdb/graphdb-free-8.6.0-dist.zip -nc http://go.pardot.com/e/45622/38-graphdb-free-8-6-0-dist-zip/5pyc3s/1295914437
cd apache-drill
wget ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz
./build.bat
```

## Drill and GraphDb for Development
In a production environment it is considered that both Drill and GraphDb are present. Other RDF stores should also work, but have not been tested yet.
### Start
```shell
./startup
```
### Stop
```shell
./shutdown
```



## Run the pipeline

The directory where the files to convert are needs to be in /data

### On Linux

```shell
time ./run.sh -f /data/<some directory within /data>

# For example to convert all tsv files in /data/pharmgkb 
time ./run.sh -f /data/pharmgkb
```

* Running options
  * **-f** (--file-directory=/data/file_repository): specify a working directory with tsv, csv and/or psv data files to convert"
  * **-gr** (--graphdb-repository=test): specify a GraphDB repository. Default: test
  * **-fo** (--format=nquads): Specify a format for RDF out when running r2rml. Default: nquads
  * **-un** (--username=import_user): Specify a format for RDF out when running r2rml. Default: import_user
  * **-pw** (--password=test): Specify a format for RDF out when running r2rml. Default: import_user

### Windows

```powershell
./run.bat /data/pharmgkb
```