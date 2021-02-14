#! /bin/sh

set -e

gcsfuse -o nonempty -o allow_other --uid $(id -u suricata) --gid $(id -g suricata) ${GCSFUSE_ARGS} ${GCS_BUCKET} /var/log/suricata;

# workaround that suricata stream change to log files without closing which is the trigger event to save change to GCS
nohup bash /log-modify-monitor.sh </dev/null >/dev/null 2>&1 &
# wait for gcsfuse mount complete before start suricata to avoid race condition

exec /suricata-docker-entrypoint.sh