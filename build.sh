#!/bin/bash

apt-get update
apt-get -y install
wget https://github.com/moshloop/konfigadm/releases/download/v0.2.4/konfigadm.deb
dpkg -i konfigadm.deb
konfigadm apply -f setup.yml -v
output_image=$(konfigadm build-image --image $image -c k8s-${runtime}.yml)

GITHUB_REPO=$(basename $(git remote get-url origin | sed 's/\.git//'))
GITHUB_USER=$(basename $(dirname $(git remote get-url origin | sed 's/\.git//')))
GITHUB_USER=${GITHUB_USER##*:}
TAG=$(git tag --points-at HEAD )
if ! git describe --exact-match HEAD 2> /dev/null; the
  echo "Skipping release of untagged commit"
  exit 0
fi

GO111MODULE=off go get github.com/aktau/github-release
go get github.com/aktau/github-release
github-release release --tag $TAG
github-release upload  --tag $TAG -f $output_image
