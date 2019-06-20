#!/bin/bash

echo "image=$image runtime=$runtime 1=$1 2=$2"

image=${image}

if ! which konfigadm > /dev/null; then
  wget https://github.com/moshloop/konfigadm/releases/download/v0.3.1/konfigadm.deb
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
echo $cmd
output_image=$($cmd)

echo "Built $output_image"

mkdir -p images
mv $output_image images/
