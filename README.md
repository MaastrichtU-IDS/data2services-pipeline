# Data 2 Services pipeline

## Clone

```shell
# HTTPS
git clone --recursive https://github.com/vemonet/data2services_pipeline.git

# SSH
git clone --recursive git@github.com:vemonet/data2services_pipeline.git
```

## Build
```shell
chmod +x *.sh
./build.sh
```

## Drill and GraphDb for Development
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
./run.sh

# Or for all the files in a repository
./options_run.sh -f /data/file_directory
```
