#!/bin/bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace
# define path to this bash script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

docker build -t usagetype_env "$SCRIPT_DIR"
docker run --name build-usagetype usagetype_env

ARTIFACT_DIR="$SCRIPT_DIR"/../elk-stack/setup/ls-config/usagetype-artifacts
if [[ ! -d "$ARTIFACT_DIR" ]]; then
    mkdir "$ARTIFACT_DIR"
fi
docker cp build-usagetype:/opt/usagetype-plugin/logstash-filter-usage_type-0.0.1.gem "$ARTIFACT_DIR"/
docker cp build-usagetype:/opt/usagetype-plugin/logstash-filter-usage_type.gemspec "$ARTIFACT_DIR"/
