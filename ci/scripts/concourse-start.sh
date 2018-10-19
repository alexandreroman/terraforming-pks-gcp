#!/usr/bin/env bash

echo "Cleaning up prior Concourse installation"
./scripts/clean-up.sh

echo "Creating Concouse Network"
docker network create concourse-net

INSTALLPATH=$PWD
dnsIP="8.8.8.8"

echo "Creating POSTGRESQL Instance for Concourse"
docker run --name concourse-db \
  --net=concourse-net \
  -h concourse-postgres \
  -p 5432:5432 \
  -e POSTGRES_USER=concourse \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=atc \
  -d postgres 
  
echo "Creating Concourse Intance"
docker run  --name concourse   -d\
  -h concourse \
  -p 8080:8080 \
  -e CONCOURSE_EXTERNAL_URL=$CONCOURSE_URL \
  --privileged \
  --net=concourse-net \
  concourse/concourse quickstart \
  --add-local-user concourse:$CONCOURSE_PASSWORD \
  --main-team-local-user concourse \
  --postgres-user=concourse \
  --postgres-password=$POSTGRES_PASSWORD \
  --postgres-host=concourse-db \
  --worker-garden-dns-server $dnsIP
  
 # --dns=$dnsIP \

echo " - Waiting for Concourse Server to come up..."
until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:8080); do
  printf '.'
  sleep 2
done

