#!/bin/bash

default_url=http://localhost:8080
url="${1:-$default_url}"

curl -s ${url}
while [ $? -ne 0 ]
do
    curl -s ${url}
done
