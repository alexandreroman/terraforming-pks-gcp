#!/bin/bash
set -o allexport

SECRETS_FILE=$1
if [ "${SECRETS_FILE}" == "" ]; then
  echo "Using default variables location at $HOME/secrets/variables.txt"
  echo "To override, provide full path to variables.txt as first argument."
  SECRETS_FILE=$HOME/secrets/variables.txt
fi

if [ ! -f ${SECRETS_FILE} ]; then
  echo "Secrets file not found: ${SECRETS_FILE}"
  exit 2
fi

source ${SECRETS_FILE}
set +o allexport

# MAKE SERVICE ACCOUNT KEY 1 LINE FOR EASIER
export GCP_SERVICE_ACCOUNT_KEY=$(tr -d '\n' < $(echo $GCP_SERVICE_ACCOUNT_KEY_PATH))

envsubst < params.yml.template > params.yml

./scripts/concourse-start.sh

#CONCOURSE_URL is the external facing URL, since we run the docker container on the same machine, 
#127.0.0.1 would always work and doesn't require access to the public web.
fly -t pks login -c 127.0.0.1:8080 -u concourse -p ${CONCOURSE_PASSWORD}
fly -t pks sync
fly -t pks set-pipeline -p deploy-pks -c pipeline.yml -l params.yml -n
fly -t pks unpause-pipeline -p deploy-pks
fly -t pks trigger-job -j deploy-pks/bootstrap-terraform-state
