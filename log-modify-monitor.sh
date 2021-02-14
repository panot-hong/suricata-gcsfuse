#!/bin/sh

# Workaround for the issue that suricata streams change to log files without closing the file which is the trigger event to save change to GCS
# Does touch to modify access time of the file triggers gcsfuse to push update
inotifywait -mr \
  --timefmt '%d/%m/%y %H:%M' --format '%T %w %f' \
  -e modify /var/log/suricata/ |
while read -r date time dir file; do
       changed_abs=${dir}${file}
       touch -a $changed_abs
       echo "At ${time} on ${date}, file $changed_abs was modified and touch access" >&2
done