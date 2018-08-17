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

### On Linux

```shell
./build.sh
```

### On Windows

* Download GraphDB and put it in the graphdb directory

  http://go.pardot.com/e/45622/38-graphdb-free-8-6-0-dist-zip/5pyc3s/1295914437

* Download Apache Drill and put it in the apache-drill directory

  ftp://apache.proserve.nl/apache/drill/drill-1.13.0/apache-drill-1.13.0.tar.gz

* Build the images

```shell
./build.bat

# Create graphdb and graphdb-import directories in /data
mkdir /data/graphdb
mkdir /data/graphdb-import
```

### Create GraphDB repo and users

* Go to http://localhost:7200/
* Setup > Repositories > Create new repository
  * Repository ID: **test** (or whatever you want it to be, but you will need to change data2services default config)
  * Check `Use context index`
  * Create
* Setup > Users and access
  * Edit admin user > Enter a new password > Save
  * Click on `Security is off` 
  * Create new user
    * User name: import_user
    * Password: test
    * Repository rights > Write right on `Any data repository`
    * Click `Create`



## Drill and GraphDb for Development

In a production environment it is considered that both Drill and GraphDb services are present. Other RDF stores should also work, but have not been tested yet.
### Start
```shell
# Linux
./startup.sh
# Windows
./startup.bat
```
### Stop
```shell
# Linux
./shutdown.sh
# Windows
./shutdown.bat
```



## Run the pipeline

The directory where the files to convert are needs to be in /data

### On Linux

```shell
time ./run.sh -f /data/<some directory within /data>

# For example to convert all tsv files in /data/pharmgkb 
./run.sh -f /data/pharmgkb
./run.sh -f /data/pharmgkb
```

* Running options
  * **-f** (--file-directory=/data/file_repository): specify a working directory with tsv, csv and/or psv data files to convert"
  * **-gr** (--graphdb-repository=test): specify a GraphDB repository. Default: test
  * **-fo** (--format=nquads): Specify a format for RDF out when running r2rml. Default: nquads
  * **-un** (--username=import_user): Specify a format for RDF out when running r2rml. Default: import_user
  * **-pw** (--password=test): Specify a format for RDF out when running r2rml. Default: import_user



### On Windows

Be careful the AntiVirus might cause problems, you might need to deactivate it

```shell
# With all default settings. Change the script if needed.
./run.bat c:/data/pharmgkb

# Running Drill
docker run -it --rm --link drill:drill -v c:/data/pharmgkb:/data autodrill -h drill -r -o /data/mapping.ttl /data/pharmgkb
```


# To do

* Automate user and repository creation at GraphDB build

* The triples are uploaded to a graph named after the directory we are running the command on. We might want to name the graph after the datasets name.

  When I run it on `/data/kraken-download/datasets` I want the triples to be uploaded to http://kraken/graph/data/kraken-download/datasets/ndc and  http://kraken/graph/data/kraken-download/datasets/pharmgkb instead of  http://kraken/graph/data/kraken-download/datasets