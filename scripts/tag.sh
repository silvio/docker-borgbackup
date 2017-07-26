#!/bin/bash

TAG_NAME=$1
TAG_VERSION=$2

TAG=""
IFS='.' read -ra VERSIONS <<< "$TAG_VERSION"
for v in "${VERSIONS[@]}"; do
  if [ -z ${TAG} ]; then SEP=""; else SEP="."; fi
  TAG=${TAG}${SEP}${v}
  if [[ ${TAG} != ${TAG_VERSION} ]]; then
    docker tag ${TAG_NAME}:${TAG_VERSION} ${TAG_NAME}:${TAG}
    echo Tagged ${TAG_NAME}:${TAG}
  fi
done
docker tag ${TAG_NAME}:${TAG_VERSION} ${TAG_NAME}:latest
echo Tagged ${TAG_NAME}:latest
