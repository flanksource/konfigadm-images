#!/bin/bash

KONFIGADM_VERSION=v0.3.1

echo "image=$image runtime=$runtime 1=$1 2=$2"
if ! which konfigadm > /dev/null; then
  wget https://github.com/moshloop/konfigadm/releases/download/$KONFIGADM_VERSION/konfigadm.deb
  dpkg -i konfigadm.deb
fi
if [[ "$image" == "" ]]; then
  image=$1
fi
if [[ "$image" == "" ]]; then
  echo "Must specify an image: "
  konfigadm build-image --list-images
  exit 1
fi
konfigadm apply -c setup.yml -v

cmd="konfigadm build-image --image $image -c k8s-docker.yml -v"
echo "Building image using: $cmd"
output_image=$($cmd)

echo "Built $output_image"

mkdir -p images
mv $output_image images/
