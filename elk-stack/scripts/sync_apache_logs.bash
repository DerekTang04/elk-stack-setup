#!/bin/bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace

LOG_TYPE=""
INGEST_ROOT=/var/elk-stack-data/filebeat/ingest
INGEST_DIR=""
S3_PATH=""

set_vars() {    
    if [[ "$LOG_TYPE" == "main" ]]; then
        INGEST_DIR="$INGEST_ROOT"/main
        S3_PATH=s3://reactome/private/logs/apache/extended_log/
    elif [[ "$LOG_TYPE" == "idg" ]]; then
        INGEST_DIR="$INGEST_ROOT"/idg
        S3_PATH=s3://reactome/private/logs/idg-apache/extended_log/
    elif [[ "$LOG_TYPE" == "reactomews" ]]; then
        INGEST_DIR="$INGEST_ROOT"/reactomews
        S3_PATH=s3://reactome/private/logs/cpws-server/tomcat7_access_logs/
    else
        exit 1
    fi
}

build_expr() {
    local SYNC_CTRL_FILE="$1"
    local OPTION="$2"
    local EXPR=""

    while IFS= read -r ARG; do
        ARG=${ARG%%\#*}
        if [[ ! "$ARG" =~ ^[[:space:]]*$ ]]; then
            [[ ! -z "$EXPR" ]] && EXPR+=" "
            EXPR+="$OPTION $ARG"
        fi
    done < "$SYNC_CTRL_FILE"

    echo "$EXPR"
}

sync_logs() {    
    local INC_EXPR="$(build_expr ${INGEST_ROOT}/.syncinclude --include)"
    local EXC_EXPR="$(build_expr ${INGEST_DIR}/.syncexclude --exclude)"
    
    echo "Syncing ${S3_PATH}"
    echo "Include Expression: ${INC_EXPR}"
    echo "Exclude Expression: ${EXC_EXPR}"
    aws s3 sync "$S3_PATH" "$INGEST_ROOT"/tmp --exclude "*" $INC_EXPR $EXC_EXPR

    find "$INGEST_ROOT"/tmp -type f | while IFS= read -r FILE; do
        FBNAME="$(basename -- ${FILE})"
        echo "$FBNAME" >> "$INGEST_DIR"/.syncexclude
    done
    sort -n -o "$INGEST_DIR"/.syncexclude "$INGEST_DIR"/.syncexclude
}

process_logs() {
    if [[ "$LOG_TYPE" != "reactomews" ]]; then
        # set prefix
        local PREFIX=$([[ "$LOG_TYPE" == "main" ]] && echo "main" || echo "idg")

        find "$INGEST_ROOT"/tmp -type f | while IFS= read -r FILE; do
            # get inflated file basename
            FBNAME="$(basename -- ${FILE})"
            INF_FBNAME="${FBNAME%.*}"
            # inflate and rename with prefix
            unpigz "$FILE"
            mv "$INGEST_ROOT"/tmp/"$INF_FBNAME" "$INGEST_ROOT"/tmp/"$PREFIX"_"$INF_FBNAME"
        done
    else
        # inflate files and remove tar
        find "$INGEST_ROOT"/tmp -type f | while IFS= read -r FILE; do 
            tar -xf "$FILE" -C "$INGEST_ROOT"/tmp
            rm "$FILE"
        done
    fi

    # move files to respective ingest_dir if they exist
    find "$INGEST_ROOT"/tmp -type f \( -name "main_*" -o -name "idg_*" -o -name "*.txt" \) | \
        grep -q . && \
        mv "$INGEST_ROOT"/tmp/* "$INGEST_DIR"
}

run_all() {
    LOG_TYPE="$1"

    set_vars
    sync_logs
    process_logs

    echo; echo
}

run_all "reactomews"
run_all "idg"
run_all "main"
