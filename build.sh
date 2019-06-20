#!/bin/bash

apt-get update
apt-get -y install
wget https://github.com/moshloop/konfigadm/releases/download/v0.3.0/konfigadm.deb
dpkg -i konfigadm.deb
konfigadm apply -c setup.yml -v
output_image=$(konfigadm build-image --image $image -c k8s-${runtime}.yml)

GITHUB_REPO=$(basename $(git remote get-url origin | sed 's/\.git//'))
GITHUB_USER=$(basename $(dirname $(git remote get-url origin | sed 's/\.git//')))
GITHUB_USER=${GITHUB_USER##*:}
TAG=$(git tag --points-at HEAD )

if [[ "$TAG" == "" ]];  then
  echo "Skipping release of untagged commit"
  exit 0
fi

wget https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2
tar zxvf linux-amd64-github-release.tar.bz2
mv bin/linux/amd64/github-release /usr/bin
github-release release --tag $TAG
github-release upload  --tag $TAG -f $output_image
