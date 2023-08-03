#!/usr/bin/env bash
set -e

case $(uname -m) in
    arm64)   cracUrl="https://cdn.azul.com/zulu/bin/zulu17.44.17-ca-crac-jdk17.0.8-linux_aarch64.tar.gz" && url=https://aka.ms/download-jdk/microsoft-jdk-17.0.8-linux-aarch64.tar.gz ;;
    *)       cracUrl="https://cdn.azul.com/zulu/bin/zulu17.44.17-ca-crac-jdk17.0.8-linux_x64.tar.gz" && url=https://aka.ms/download-jdk/microsoft-jdk-17.0.8-linux-x64.tar.gz ;;
esac

echo "Using CRaC enabled JACK $cracUrl"
echo "Using JDK $url"

./mvnw clean package
cp ./readiness.sh ./crac-demo/target

# Build image spring-boot-demo without checkpoint/restore
docker build -t spring-boot-demo --build-arg JDK_URL=$url --file Dockerfile-no-crac ./demo

# Build image spring-boot-startup-crac-demo with the checkpoint of startup
docker build -t spring-boot-startup-crac-demo:builder --build-arg CRAC_JDK_URL=$cracUrl --file Dockerfile-startup-crac ./crac-demo
docker run -d --privileged --rm --name=spring-boot-startup-crac-demo --ulimit nofile=1024 -p 8080:8080 -v $(pwd)/crac-demo/target:/opt/mnt spring-boot-startup-crac-demo:builder
echo "$(date): Please wait until the checkpoint of startup is done..."
while [ -z "$(docker exec spring-boot-startup-crac-demo sh -c 'ls -A /opt/app/checkpoint')" ]
do
    sleep 5
done
sleep 10
echo $(docker exec spring-boot-startup-crac-demo sh -c 'cat /opt/app/checkpoint/log')
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint.sh"]' $(docker ps -qf "name=spring-boot-startup-crac-demo") spring-boot-startup-crac-demo:checkpoint
docker kill $(docker ps -qf "name=spring-boot-startup-crac-demo")

# Build image spring-boot-warmup-crac-demo with the checkpoint of warmup
docker build -t spring-boot-warmup-crac-demo:builder --build-arg CRAC_JDK_URL=$cracUrl --file Dockerfile-warmup-crac ./crac-demo
docker run -d --privileged --rm --name=spring-boot-warmup-crac-demo --ulimit nofile=1024 -p 8080:8080 -v $(pwd)/crac-demo/target:/opt/mnt spring-boot-warmup-crac-demo:builder
echo "$(date): Please wait until the checkpoint of warmup is done..."
while [ -z "$(docker exec spring-boot-warmup-crac-demo sh -c 'ls -A /opt/app/checkpoint')" ]
do
    sleep 5
done
sleep 10
echo $(docker exec spring-boot-warmup-crac-demo sh -c 'cat /opt/app/checkpoint/log')
docker commit --change='ENTRYPOINT ["/opt/app/entrypoint-warmup.sh"]' $(docker ps -qf "name=spring-boot-warmup-crac-demo") spring-boot-warmup-crac-demo:checkpoint
docker kill $(docker ps -qf "name=spring-boot-warmup-crac-demo")
