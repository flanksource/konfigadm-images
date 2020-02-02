#!/bin/bash
set -o verbose

[[ "$NAME" == "" ]]         && NAME=$(basename $(git remote get-url origin | sed 's/\.git//'))
[[ "$GITHUB_USER" == "" ]]  && GITHUB_USER=$(basename $(dirname $(git remote get-url origin | sed 's/\.git//')))
[[ "$GITHUB_TOKEN" == "" ]] && GITHUB_TOKEN=$(cat .gh-token)
[[ "$TAG" == "" ]]          && TAG=$(git tag --points-at HEAD )

GITHUB_USER=moshloop
NAME=konfigadm-images

snap install docker

image=$(echo $1 |  tr -d '[:space:]')
config=$(echo $2 |  tr -d '[:space:]')

konfigadm="docker run --rm -u root --privileged -v /dev/kvm:/dev/kvm -v $PWD:$PWD -w $PWD -v /root/.konfigadm:/root/.konfigadm flanksource/konfigadm:v0.5.1-1-ga21ebd7"

if [[ "$image" == "" ]]; then
  echo "Must specify an image: "
  $konfigadm images list
  exit 1
fi


filename="$(basename $image | sed 's/:/_/')"
extension="${filename##*.}"
filename="$(echo $config)-${filename%.*}-$(date +"%V%u-%H%M%S").img"
mkdir -p images
$konfigadm images build --image "$image" --resize +2G --output-filename "$filename" --output-dir images "${config}.yml" -v

if ! which gitub-release; then
  wget https://github.com/aktau/github-release/releases/download/v0.7.2/linux-amd64-github-release.tar.bz2
  tar -xjvf linux-amd64-github-release.tar.bz2 --strip-components=3 -C /usr/bin/
fi

echo Creating release
github-release release \
    --user $GITHUB_USER \
    --repo $NAME \
    --tag $TAG \
    --pre-release

cd images
$konfigadm images convert --image "$image" --output-dir images

for img in $(ls images); do
  echo Uploading $img
  github-release upload \
      --user $GITHUB_USER \
      --repo $NAME \
      --tag $TAG \
      --name $img \
      --file $img
done
