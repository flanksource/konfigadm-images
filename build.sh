#!/bin/bash
set -o verbose
[[ "$NAME" == "" ]]         && NAME=$(basename $(git remote get-url origin | sed 's/\.git//'))
[[ "$GITHUB_USER" == "" ]]  && GITHUB_USER=$(basename $(dirname $(git remote get-url origin | sed 's/\.git//')))
[[ "$GITHUB_TOKEN" == "" ]] && GITHUB_TOKEN=$(cat .gh-token)
[[ "$TAG" == "" ]]          && TAG=$(git tag --points-at HEAD )

GITHUB_USER=${GITHUB_USER##*:}

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

if ! which go; then
  sudo snap install go --classic
fi

if ! which gcloud; then
  sudo snap install google-cloud-sdk --classic
fi

if ! which qemu-system-x86; then
  sudo apt-get install -y qemu-system-x86 kpart python-pexpec python-serial libguestfs-tools
fi


# konfigadm apply -c setup.yml -v
filename="$(basename $image | sed 's/:/_/')"
extension="${filename##*.}"
filename="$(echo $config)-${filename%.*}-$(date +"%V%u-%H%M%S").img"
mkdir -p images
konfigadm images build --image "$image" --resize +2G --output-filename "$filename" --output-dir images "${config}.yml" -v
go get github.com/aktau/github-release

echo Creating release
github-release release \
    --user $GITHUB_USER \
    --repo $NAME \
    --tag $TAG \
    --pre-release



cd images
if ! which ovftool; then
  gsutil cp gs://moshloop-image-builder/VMware-ovftool-4.3.0-12320924-lin.x86_64.bundle .
  chmod +x VMware-ovftool-4.3.0-12320924-lin.x86_64.bundle
  sudo ./VMware-ovftool-4.3.0-12320924-lin.x86_64.bundle --eulas-agreed --required
fi
konfigadm images convert --image "$image" --output-dir images


for img in $(ls images); do
  echo Uploading $img
  github-release upload \
      --user $GITHUB_USER \
      --repo $NAME \
      --tag $TAG \
      --name $img \
      --file $img
done
