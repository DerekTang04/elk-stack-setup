#!/usr/bin/env bash

# USAGE
#
# builds logstash usage_type plugin if necessary
#
# launches elk stack once .gem and .gemspec files are avail

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

echo "waiting for plugins..."
while [[ ! -e "$PLUGIN_DIR"/usagetype-plugin/logstash-filter-usage_type-0.0.1.gem ]] || [[ ! -e "$PLUGIN_DIR"/usagetype-plugin/logstash-filter-usage_type.gemspec ]]; do
    sleep 5
done

echo "launching stack!"
cd "$ROOT_DIR" && docker compose up -d --build
