#!/bin/bash

TAG_NAME=$1
TAG_VERSION=$2

TAG=""
IFS='.' read -ra VERSIONS <<< "$TAG_VERSION"
for v in "${VERSIONS[@]}"; do
  if [ -z ${TAG} ]; then SEP=""; else SEP="."; fi
  TAG=${TAG}${SEP}${v}
  docker push ${TAG_NAME}:${TAG}
  echo Pushed ${TAG_NAME}:${TAG}
done
docker push ${TAG_NAME}:latest
echo Pushed ${TAG_NAME}:latest
