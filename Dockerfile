FROM jasonish/suricata:6.0

RUN \
echo \
$'[gcsfuse]\n\
name=gcsfuse (packages.cloud.google.com)\n\
baseurl=https://packages.cloud.google.com/yum/repos/gcsfuse-el7-x86_64\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg \
 https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'\
> /etc/yum.repos.d/gcsfuse.repo

# install gcsfuse
RUN yum -y install gcsfuse
# install inotify-tools
RUN yum install -y epel-release && yum update -y && yum install -y inotify-tools

ENV GOOGLE_APPLICATION_CREDENTIALS=/etc/gcloud/service-account.json
ENV GCS_BUCKET=my-bucket
ENV GCSFUSE_ARGS=""

COPY /log-modify-monitor.sh /
RUN cp /docker-entrypoint.sh /suricata-docker-entrypoint.sh
COPY /docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]