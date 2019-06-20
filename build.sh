#!/bin/bash

image=${image}

if ! which konfigadm > /dev/null; then
  wget https://github.com/moshloop/konfigadm/releases/download/v0.3.0/konfigadm.deb
  dpkg -i konfigadm.deb
fi
[[ "$image" == "" ]] && image=$1
if [[ "$image" == "" ]]; then
  echo "Must specify an image: "
  konfigadm build-image --list-images
  exit 1
fi
konfigadm apply -c setup.yml -v

cmd="konfigadm build-image --image $image -c k8s-docker.yml -v"
echo $cmd
output_image=$($cmd)

GITHUB_REPO=$(basename $(git remote get-url origin | sed 's/\.git//'))
GITHUB_USER=$(basename $(dirname $(git remote get-url origin | sed 's/\.git//')))
GITHUB_USER=${GITHUB_USER##*:}
TAG=$(git tag --points-at HEAD )

if [[ "$TAG" == "" ]];  then
  echo "Skipping release of untagged commit"
  exit 0
fi

wget https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2
tar jxvf linux-amd64-github-release.tar.bz2
mv bin/linux/amd64/github-release /usr/bin
github-release release --tag $TAG
github-release upload  --tag $TAG -f $output_image
