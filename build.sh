#!/bin/bash
set -x
KONFIGADM_VERSION=v0.3.4
image=$1
config=$2
if ! which konfigadm > /dev/null; then
  wget https://github.com/moshloop/konfigadm/releases/download/$KONFIGADM_VERSION/konfigadm.deb
  dpkg -i konfigadm.deb
fi
if [[ "$image" == "" ]]; then
  echo "Must specify an image: "
  konfigadm build-image --list-images
  exit 1
fi
konfigadm apply -c setup.yml -v

cmd="konfigadm build-image --image $image ${config}.yml --resize +2G -v"
echo "Building image using: $cmd"
output_image=$($cmd)

echo "Built $output_image"

extension="${output_image##*.}"
filename="${output_image%.*}"

mkdir -p images
mv $output_image images/${config}_${filename}.${extension}
