#!/bin/bash
set -o allexport

SECRETS_FILE=$1
if [ "${SECRETS_FILE}" == "" ]; then
  echo "Missing secrets file"
  exit 1
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

fly -t pks login -c ${CONCOURSE_URL} -u concourse -p ${CONCOURSE_PASSWORD}
fly -t pks sync
fly -t pks set-pipeline -p deploy-pks -c pipeline.yml -l params.yml -n
fly -t pks unpause-pipeline -p deploy-pks
fly -t pks trigger-job -j deploy-pks/bootstrap-terraform-state
