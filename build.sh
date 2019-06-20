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
echo "Releasing $GITHUB_REPO/$GITHUB_USER:$TAG"
github-release release --tag $TAG
echo "Uploading $output_image"
github-release upload  --tag $TAG -f $output_image
