# Data 2 Services pipeline
This is a demonstrator ETL pipeline that converts PharmGKB data into a generic RDF-format and loads it into a GraphDb endpoint. 

After the enpoint is started up, a repository called "test", and a user called "import_user" (password "test") with write permissons to the test repository need to be configured. Also security has to be enabled.

This pipeline has been tested with PharmGKB (located in /data/pharmgkb) and HGNC data on both Linux and Mac OS-X running the latest Docker-CE version. This pipeline should also work on Windows. Paths from "/data" need to be changed to "c:/data".

## Clone

```shell
# HTTPS
git clone --recursive https://github.com/MaastrichtU-IDS/data2services-pipeline.git

# SSH
git clone --recursive git@github.com:MaastrichtU-IDS/data2services-pipeline.git
```

## Build
Downloads the files and builds the docker containers if required.
```shell
./build.sh
```

## Drill and GraphDb for Development
In a production environment it is considered that both Drill and GraphDb are present. Other RDF stores should also work, but have not been tested yet.
### Start
```shell
./startup.sh
```
### Stop
```shell
./shutdown.sh
```

## Run the pipeline
```shell
time ./run.sh -f /data/<some directory within /data>
```

