# Suricata + gcsfuse
Suricata 6.01 with gcsfuse to sync log files to GCS (Google Cloud Storage). This image can also be found at [panot/suricata-gcsfuse](https://hub.docker.com/r/panot/suricata-gcsfuse). This image use suricata image from [jasonish/suricata](https://hub.docker.com/r/jasonish/suricata/) as a base image and extend with installation and configuration of gcsfuse.

## What is Suricata
[Suricata](https://suricata-ids.org) is a free and open source, mature, fast and robust network threat detection engine.

## What is gcsfuse
[gcsfuse](https://cloud.google.com/storage/docs/gcs-fuse) is a library that use fuse mount to sync data to and from Google Cloud Storage.

## Usage
Build image
```
docker build -t suricata-gcsfuse . --no-cache
```
Run container 
```
docker run --rm --privileged --name suricata-gcsfuse --net=host \
    --cap-add=net_admin --cap-add=sys_nice \
    -v $(pwd)/log:/var/log/suricata -v $(pwd)/secret:/etc/gcloud \
    -e GCSFUSE_ARGS="--limit-ops-per-sec 1000" \
    -e GCSFUSE_BUCKET=suricata-log \
    -e GOOGLE_APPLICATION_CREDENTIALS=/etc/gcloud/service-account.json \
    -e SURICATA_OPTIONS="-i eth0 --set outputs.1.eve-log.enabled=no --set stats.enabled=no --set http-log.enabled=yes --set tls-log.enabled=yes" suricata-gcsfuse 
```
Running above command will create and run a container that accommodate a gcsfuse inside.

**Flag `--privileged` is required for gcsfuse and `--net=host` to connect to the host network so suricata can detect suspicious request on host network.**

### Environment Variables
`GCSFUSE_ARGS` - gcsfuse arguments, see more details at https://github.com/GoogleCloudPlatform/gcsfuse - <i>default is empty</i>. 
`GCS_BUCKET` - Google Cloud Storage bucket name to sync to - <i>default is my-bucket</i>.  
`GOOGLE_APPLICATION_CREDENTIALS` - path to the service account json file within the container - <i>default is /etc/gcloud/service-account.json</i>.  
`SURICATA_OPTIONS` - suricata options, see more details at https://suricata.readthedocs.io/en/suricata-6.0.1/command-line-options.html - <i>default is empty</i>.

## Known Issues and Workaround
gcsfuse only save file change to GCS when a file is **write and close**, only modify without close does not trigger gcsfuse to sync up to the GCS. While Suricata write log files with open and write method, stream never get closed until the suricata app stopped. To diagnose this simply `stat` those log file during the suricata startup like `stat /var/log/suricata/suricata.log` it should show atime (access time) is not changed but mtime (modify time) keep changing when log file is written.

The workaround of this is to use `inotifywait` to monitor event modify of /var/log/suricata/ directory. When the event is raised then `touch -a [file]` to update atime and that automatically trigger gcsfuse to sync change to the GCS.

This workaround is already in place in `log-modify-monitor.sh` bash file.

## Setup on Google Cloud VM / Instance Template
To use this docker image on Google Cloud VM with Container-Optimized OS, use [setup.sh](setup.sh) as a startup script.

## License
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)