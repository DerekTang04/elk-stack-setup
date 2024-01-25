#!/usr/bin/env bash

# USAGE
# 
# bind mounted into a cron job(/etc/cron.daily) on the filebeat container
#
# deletes logs from filebeat ingest once read is complete

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace

WORKING_DIR="/usr/share/filebeat"

REG_FILE="$(cat $WORKING_DIR/data/registry/filebeat/active.dat)"

while IFS= read -r ENTRY; do
    if [[ "$ENTRY" == "[" ]] || [[ "$ENTRY" == "]" ]]; then
        continue
    fi   
    if [[ "${ENTRY: -1}" == "," ]]; then
        ENTRY="${ENTRY%?}"
    fi

    LOG_FILE="$(echo "$ENTRY" | jq '.meta.source')"
    LOG_FILE="${LOG_FILE//\"/}"
    OFFSET="$(echo "$ENTRY" | jq '.cursor.offset')"
    
    if [[ -e "$LOG_FILE" ]]; then
        BYTES="$(wc -c "$LOG_FILE" | awk '{print $1}')"
        if [[ "$BYTES" -eq "$OFFSET" ]]; then
            rm -f $LOG_FILE
        fi
    fi
done < "$REG_FILE"
