#!/usr/bin/env bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace
# define path to this bash script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ROOT_DIR="$SCRIPT_DIR"/..

PLUGIN_DIR="$ROOT_DIR"/setup/ls-config/plugins
if [[ ! -e "$PLUGIN_DIR"/usagetype-plugin/logstash-filter-usage_type-0.0.1.gem ]] || [[ ! -e "$PLUGIN_DIR"/usagetype-plugin/logstash-filter-usage_type.gemspec ]]; then
    echo "building plugins..."
    "$PLUGIN_DIR"/build-plugin.bash
fi

#echo "copying certs..."
#KIB_CERTS_DIR="$ROOT_DIR"/certs/kibana
#cp /etc/letsencrypt/live/sunshine.reactome.org/fullchain.pem "$KIB_CERTS_DIR"/kibana.crt
#cp /etc/letsencrypt/live/sunshine.reactome.org/privkey.pem "$KIB_CERTS_DIR"/kibana.key
#chmod g+r "$KIB_CERTS_DIR"/kibana.key

echo "waiting for plugins..."
while [[ ! -e "$PLUGIN_DIR"/usagetype-plugin/logstash-filter-usage_type-0.0.1.gem ]] || [[ ! -e "$PLUGIN_DIR"/usagetype-plugin/logstash-filter-usage_type.gemspec ]]; do
    sleep 5
done

echo "launching stack!"
cd "$ROOT_DIR" && docker compose up -d --build
