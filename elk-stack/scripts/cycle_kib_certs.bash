#!/bin/bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace

docker exec -i elk-stack-kibana-1 bash -c "ps aux | grep /usr/share/kibana/bin | grep -v grep | awk '{print \$2}' | xargs -I {} kill -SIGHUP {}"
