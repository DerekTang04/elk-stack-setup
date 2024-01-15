#!/usr/bin/env bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace
# define path to this bash script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# DOCKER_WORKING_DIR begins with '//' instead of '/'
# arg_working_dir is not set properly if '/' is used
# observed with Git Bash(v2.43.0) and Docker(v24.0.7) on Windows 10 
# unknown if this bug(?) occurs on Linux systems
DOCKER_WORKING_DIR="//usr/share/usagetype-plugin"

docker build -t build_usagetype_env --build-arg arg_working_dir="$DOCKER_WORKING_DIR" "$SCRIPT_DIR"
docker run -d \
    --rm \
    --name build_usagetype \
    --mount type=bind,source="$SCRIPT_DIR"/usagetype-plugin,target="$DOCKER_WORKING_DIR" \
    build_usagetype_env
