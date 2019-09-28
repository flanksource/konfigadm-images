#!/bin/bash
set -o verbose
KONFIGADM_VERSION=0.4.0
image=$(echo $1 |  tr -d '[:space:]')
config=$(echo $2 |  tr -d '[:space:]')
if ! which konfigadm > /dev/null; then
  wget https://github.com/moshloop/konfigadm/releases/download/$KONFIGADM_VERSION/konfigadm.deb
  dpkg -i konfigadm.deb
fi
if [[ "$image" == "" ]]; then
  echo "Must specify an image: "
  konfigadm images list
  exit 1
fi
konfigadm apply -c setup.yml -v
filename="$(basename $image | sed 's/:/_/')"
extension="${filename##*.}"
filename="$(echo $config)-${filename%.*}-$(date +"%V%u-%H%M%S").img"
mkdir -p images
konfigadm images build --image "$image" --resize +2G --output-filename "$filename" --output-dir images "${config}.yml" -v
konfigadm images convert --image "$image" --output-dir images
gsutil cp images/* gs://moshloop-image-builder/
