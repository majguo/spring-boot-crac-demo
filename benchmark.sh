#!/bin/bash
set -e

echo "The first response time for container without checkpoint/restore:"

docker run -d --rm -p 8080:8080 --name spring-boot-demo spring-boot-demo

time ./readiness.sh

docker kill $(docker ps -qf "name=spring-boot-demo")

echo ""
echo "================================="
echo ""

echo "The first response time for container restoring from the checkpoint of startup:"

docker run -d --rm -p 8080:8080 --name spring-boot-startup-crac-demo spring-boot-startup-crac-demo:checkpoint

time ./readiness.sh

docker kill $(docker ps -qf "name=spring-boot-startup-crac-demo")

echo ""
echo "================================="
echo ""

echo "The first response time for container restoring from the checkpoint of warmup:"

docker run -d --rm -p 8080:8080 --name spring-boot-warmup-crac-demo spring-boot-warmup-crac-demo:checkpoint

time ./readiness.sh

docker kill $(docker ps -qf "name=spring-boot-warmup-crac-demo")
