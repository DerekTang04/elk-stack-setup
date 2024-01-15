#!/usr/bin/env bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace
# define path to this bash script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

"$SCRIPT_DIR"/logstash-7.4.0/gradlew jar
"$SCRIPT_DIR"/gradlew assemble
"$SCRIPT_DIR"/gradlew gem
