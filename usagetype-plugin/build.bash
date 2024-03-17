#!/bin/bash

# exit on attempt to use undeclared variable
set -o nounset
# enable error tracing
set -o errtrace

cd ./logstash-7.4.0 && ./gradlew jar
cd .. && ./gradlew assemble && ./gradlew gem
