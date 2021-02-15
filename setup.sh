#! /bin/bash

set -e
set -x

SURICATA_CONTAINER_NAME="suricata-gcsfuse"
SURICATA_IMAGE="panot/suricata-gcsfuse:6.0"

# COS protects /root/ as read-only while docker-credential-gcr configure-docker will attempt to create /root/.docker folder for docker configuration
# hence it will fail instead we override the home directory of root user
# https://stackoverflow.com/a/51237418/6837989
HOME_ROOT="/home/root"
HOME_ROOT_OVERRIDE="sudo HOME=${HOME_ROOT}"

# Authenticating with Private Google Container Registry For COS Instance
${HOME_ROOT_OVERRIDE} docker-credential-gcr configure-docker

# Unmount if it is previously mounted
fusermount -u /var/log/suricata || true

if [ ! "$(docker ps -q -f name=${SURICATA_CONTAINER_NAME})" ]; then

    if [ "$(docker ps -aq -f status=exited -f name=${SURICATA_CONTAINER_NAME})" ]; then
    # cleanup
    ${HOME_ROOT_OVERRIDE} docker rm ${SURICATA_CONTAINER_NAME}
    fi

    # download service account key file of suricata svc to /home/root/
    mkdir -p /etc/gcloud

    curl -X GET \
    -H "Authorization: Bearer $(curl --silent --header  "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)" \
    -o "/etc/gcloud/service-account.json" \
    "https://www.googleapis.com/storage/v1/b/[bucket name]/o/[service account to run gcsfuse.json]?alt=media"

    ${HOME_ROOT_OVERRIDE} docker run --privileged -d --restart=on-failure:5 --name ${SURICATA_CONTAINER_NAME} \
    --net=host --cap-add=net_admin --cap-add=sys_nice \
    -v /var/log/suricata:/var/log/suricata -v /etc/gcloud:/etc/gcloud \
    -e GCSFUSE_BUCKET=[your suricata log bucket name] -e GCSFUSE_ARGS="--limit-ops-per-sec 100" -e GOOGLE_APPLICATION_CREDENTIALS=/etc/gcloud/service-account.json \
    -e SURICATA_OPTIONS="-i eth0 --set outputs.1.eve-log.enabled=no --set stats.enabled=no --set http-log.enabled=yes --set tls-log.enabled=yes" \
    ${SURICATA_IMAGE}

    # remove stream-events rules from the suricata rules as it has many false positive alerts
    ${HOME_ROOT_OVERRIDE} docker exec -t ${SURICATA_CONTAINER_NAME} suricata-update --ignore stream-events.rules --ignore "*-deleted.rules"
fi