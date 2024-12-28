#!/bin/bash

mkdir -p materials
docker run \
  --mount type=bind,source="$(pwd)/materials",destination=/jailhouse-build/materials \
  -it \
  jailhouse-build \
  $1 $2
