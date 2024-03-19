#!/bin/bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace

INGEST_ROOT=/var/elk-stack-data/filebeat/ingest
REGISTRY_DIR=/var/elk-stack-data/filebeat/fbdata01/registry/filebeat

find "$INGEST_ROOT" -type f \( -name "main_*" -o -name "idg_*" -o -name "*.txt" \) | \
while IFS= read -r DATA_FILE; do
    # get file basename and size, init offset
    DF_BNAME="$(basename -- ${DATA_FILE})"
    BYTES="$(wc -c ${DATA_FILE} | awk '{print $1}')"
    OFFSET=0

    # try to find offset from log
    ENTRY="$(grep ${DF_BNAME} ${REGISTRY_DIR}/log.json | tail -1)"
    if [[ ! "$ENTRY" =~ ^[[:space:]]*$ ]]; then
        OFFSET="$(echo ${ENTRY} | jq '.v.cursor.offset')"
    fi

    # if log is missing offset, try to find from snapshot
    if [[ "$OFFSET" -eq 0 && -f "${REGISTRY_DIR}/active.dat" ]]; then
        SNAPSHOT="$(ls ${REGISTRY_DIR} | grep -v 'active\|log\|meta')"
        ENTRY="$(grep ${DF_BNAME} ${REGISTRY_DIR}/${SNAPSHOT} || true)"
        
        if [[ ! "$ENTRY" =~ ^[[:space:]]*$ ]]; then
            if [[ "${ENTRY: -1}" == "," ]]; then
                ENTRY="${ENTRY::-1}"
            fi
            OFFSET="$(echo ${ENTRY} | jq '.cursor.offset')"
        fi
    fi

    # remove file if file size equals read offset
    if [[ "$BYTES" -eq "$OFFSET" ]]; then
        rm -f "$DATA_FILE"
    fi
done
