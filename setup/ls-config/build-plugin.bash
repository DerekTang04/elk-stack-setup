#!/usr/bin/env bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace
# define path to this bash script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

docker build -t build_usagetype_env "$SCRIPT_DIR"
docker run -d \
    -it \
    --name build_usagetype \
    --mount type=bind,source="$SCRIPT_DIR"/usagetype-plugin,target=/usr/share/usagetype-plugin \
    build_usagetype_env
