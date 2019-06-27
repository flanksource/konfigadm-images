#!/bin/bash
set -o verbose
KONFIGADM_VERSION=v0.3.5
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
filename="$(basename $image)"
extension="${filename##*.}"
filename="$(echo $config | sed 's/:/_/') -${filename%.*}-$(date +%Y%m%d%M%H%M%S).img"
mkdir -p images
konfigadm build-image --image $image ${config}.yml --resize +2G  --output-filename $filename --output-dir images -v
