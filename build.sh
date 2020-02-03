#!/bin/bash
set -o verbose

export
[[ "$GITHUB_TOKEN" == "" ]] && GITHUB_TOKEN=$(cat .gh-token)
[[ "$TAG" == "" ]] && TAG=$(date "+%Y%m%d%H%M%S")

GITHUB_USER=moshloop
NAME=konfigadm-images
KONFIGADM_VERSION=v0.5.3

image=$(echo $1 |  tr -d '[:space:]')
config=$(echo $2 |  tr -d '[:space:]')
cd workspace
[[ "$GITHUB_TOKEN" == "" ]] && GITHUB_TOKEN=$(cat .gh-token)
konfigadm="docker run --rm -u root --privileged -v /dev/kvm:/dev/kvm -v $PWD:$PWD -w $PWD -v /root/.konfigadm:/root/.konfigadm flanksource/konfigadm:$KONFIGADM_VERSION konfigadm "

$konfigadm version

if [[ "$image" == "" ]]; then
  echo "Must specify an image: "
  $konfigadm images list
  exit 1
fi


filename="$(basename $image | sed 's/:/_/')"
extension="${filename##*.}"
filename="$(echo $config)-${filename%.*}-$(date "+%Y-%m-%d-%H%M%S")"
ova=${filename}.ova
filename=${filename}.img
mkdir -p images
$konfigadm images build --image "$image" --resize +2G --output-filename "$filename" --output-dir images "${config}.yml" -v

if ! which gitub-release; then
  wget -nv https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2
  tar -xjvf linux-amd64-github-release.tar.bz2 --strip-components=3 -C /usr/bin/
fi

echo Creating release $GITHUB_USER/$NAME/$TAG
github-release  -v release \
    --user $GITHUB_USER \
    --repo $NAME \
    --tag $TAG \
    --security-token $GITHUB_TOKEN \
    --pre-release

$konfigadm images convert --image images/$filename  -v

# for img in $(ls images); do
echo Uploading $ova
github-release -v  upload \
    --user $GITHUB_USER \
    --repo $NAME \
    --tag $TAG \
    --name $ova \
    --security-token $GITHUB_TOKEN \
    --file $ova

tar -czvf ${filename}.tgz images/$filename

echo Uploading img
github-release -v  upload \
    --user $GITHUB_USER \
    --repo $NAME \
    --tag $TAG \
    --name ${filename}.tgz \
    --security-token $GITHUB_TOKEN \
    --file ${filename}.tgz

# done
