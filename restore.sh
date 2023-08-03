#!/usr/bin/env bash
set -e

docker run --rm -p 8080:8080 --name spring-boot-warmup-crac-demo spring-boot-warmup-crac-demo:checkpoint
