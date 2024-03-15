#!/usr/bin/env bash

# exit on error
set -e
# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace

# define path to this bash script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# define elk root
ELK_ROOT="$SCRIPT_DIR"/..

if [[ ! -f "$ELK_ROOT"/.env ]]; then
    echo "[ERROR] .env is missing!"
    exit 1
fi

if [[ ! -f "$ELK_ROOT"/reporting/.netrc ]]; then
    echo "[WARN] reporting/.netrc is missing!"
fi

if [[ ! -f "$ELK_ROOT"/setup/ls-config/ips_with_usage_types.csv ]]; then
    echo "[WARN] setup/ls-config/ips_with_usage_types.csv is missing!"
fi

if [[ ! -f "$ELK_ROOT"/setup/ls-config/usagetype-artifacts/logstash-filter-usage_type-0.0.1.gem ]]; then
    echo "[WARN] filter_usage_type gem file is missing in setup/ls-config/usagetype-artifacts!"
fi

if [[ ! -f "$ELK_ROOT"/setup/ls-config/usagetype-artifacts/logstash-filter-usage_type.gemspec ]]; then
    echo "[WARN] filter_usage_type gem spec file is missing in setup/ls-config/usagetype-artifacts!"
fi

echo "launching stack..."; echo
cd "$ELK_ROOT" && docker compose up -d --build
