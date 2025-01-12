#!/bin/bash

workdir=/jailhouse-build

mkdir -p materials

docker run \
  --rm \
  --mount type=volume,source=jailhouse-build-cache,destination=${workdir}/cache \
  --mount type=bind,source="$(pwd)/materials",destination=${workdir}/materials \
  -it \
  jailhouse-build \
  $@
