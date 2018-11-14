# Data 2 Services pipeline
This is a demonstrator ETL pipeline that converts PharmGKB data into a generic RDF-format and loads it into a GraphDb endpoint. 

After the enpoint is started up, a repository called "test", and a user called "import_user" (password "test") with write permissons to the test repository need to be configured. Also security has to be enabled.

This pipeline has been tested with PharmGKB (located in /data/pharmgkb) and HGNC data on both Linux and Mac OS-X running the latest Docker-CE version. This pipeline should also work on Windows. Paths from "/data" need to be changed to "c:/data".

## Linux

### Clone

```shell
# WARNING: for Windows execute it before cloning to fix bugs with newlines
git config --global core.autocrlf false
# HTTPS
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-pipeline.git
# SSH
git clone --recursive git@github.com:MaastrichtU-IDS/data2services-pipeline.git
```

### Build

Downloads the files and builds the docker containers if required.

```shell
./build.sh
```

### Drill and GraphDb for Development

In a production environment it is considered that both Drill and GraphDb services are present. Other RDF stores should also work, but have not been tested yet.

```shell
# Start
./startup.sh
# Stop
./shutdown.sh
```

### Run

The directory where are the files to convert needs to be in /data. Change the WORKING_DIRECTORY in config.yaml file if required.

```shell
./run.sh /path/to/data2services-pipeline/config.yaml
```



## Windows

All windows scripts are in directory `windows_scripts`

```powershell
dir windows_scripts
```

### Build

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
# With all default settings. Change the script if needed.
./run.bat c:/data/pharmgkb

# Running Drill
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





# To do

* Automate user and repository creation at GraphDB build

* The triples are uploaded to a graph named after the directory we are running the command on. We might want to name the graph after the datasets name.

  When I run it on `/data/kraken-download/datasets` I want the triples to be uploaded to http://kraken/graph/data/kraken-download/datasets/ndc and  http://kraken/graph/data/kraken-download/datasets/pharmgkb instead of  http://kraken/graph/data/kraken-download/datasets

