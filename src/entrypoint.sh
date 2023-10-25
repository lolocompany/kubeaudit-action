#!/usr/bin/env bash

set -xe
set -o pipefail

PATH=${1}
PATH_TO_VALUES=${11}
KUBEAUDIT_COMMANDS=${2:-all}
HELM=${3:-3}
KUBEAUDIT_FORMAT=${4}
KUBEAUDIT_MINSEVERITY=${5}
KUBEAUDIT_INCLUDEGENEREATED=${6}
KUBEAUDIT_VER=${7}
HELMV2_VER=${8}
HELMV3_VER=${9}
KUBEAUDIT_CONFIG=${10}
IFS=","

if [[ "${HELMV2_VER}" != "" ]]; then
  curl -sL https://get.helm.sh/helm-v${HELMV2_VER}-linux-amd64.tar.gz | \
  tar xz && mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64
fi

if [[ "${HELMV3_VER}" != "" ]]; then
  curl -sL https://get.helm.sh/helm-v${HELM_VER}-linux-amd64.tar.gz | \
  tar xz && mv linux-amd64/helmv3 /usr/local/bin/helm && rm -rf linux-amd64
fi

if [[ "${KUBEAUDIT_VER}" != "" ]]; then
  curl -sSL https://github.com/Shopify/kubeaudit/releases/download/v${KUBEAUDIT_VER}/kubeaudit_${KUBEAUDIT_VER}_linux_amd64.tar.gz | \
  tar xz && mv kubeaudit /usr/local/bin/kubeaudit
fi


if [[ "${KUBEAUDIT_COMMANDS}" == "" ]]; then
  echo "No commands provided"
  exit 1
fi

if [[ "${PATH}" == "" ]]; then
  echo "No path provided"
  exit 1
fi

HELM_CMD=/usr/local/bin/helmv3
if [[ "${HELM}" == "2" ]]; then
  HELM_CMD=/usr/local/bin/helm
fi

if [[ "${KUBEAUDIT_FORMAT}" != "" ]]; then
  KUBEAUDIT_FORMAT="-p ${KUBEAUDIT_FORMAT}"
fi

if [[ "${KUBEAUDIT_MINSEVERITY}" != "" ]]; then
  KUBEAUDIT_MINSEVERITY="-m ${KUBEAUDIT_MINSEVERITY}"
fi

if [[ "${KUBEAUDIT_INCLUDEGENEREATED}" == "true" ]]; then
  KUBEAUDIT_INCLUDEGENEREATED="--includegenerated"
fi

if [[ "${KUBEAUDIT_CONFIG}" != "" ]]; then
  echo ">>> File Checking"
  /bin/ls -l
  KUBEAUDIT_CONFIG="-k ${KUBEAUDIT_CONFIG}"
fi

if [[ "${PATH_TO_VALUES}" != "" ]]; then
  PATH_TO_VALUES="-f ${PATH_TO_VALUES}"
fi

helm_cmd="${HELM_CMD} template ${PATH} ${PATH_TO_VALUES} > manifest.yaml"
echo $helm_cmd
eval $helm_cmd

for command in ${KUBEAUDIT_COMMANDS}; do
  echo ">>> kubeaudit version check"
  /usr/local/bin/kubeaudit version
  echo ">>> Executing kubeaudit command ${command}"
  cmd="/usr/local/bin/kubeaudit ${command} ${KUBEAUDIT_INCLUDEGENEREATED} ${KUBEAUDIT_FORMAT} ${KUBEAUDIT_MINSEVERITY} ${KUBEAUDIT_CONFIG} -f manifest.yaml"
  echo $cmd
  eval $cmd
done
