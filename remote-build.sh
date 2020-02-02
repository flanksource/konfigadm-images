#!/bin/bash

# Always delete instance after attempting build
function cleanup {
  gcloud compute instances delete ${INSTANCE_NAME} --quiet --delete-disks=all
}

# Configurable parameters
[ -z "$COMMAND" ] && echo "Need to set COMMAND" && exit 1;

USERNAME=${USERNAME:-admin}
REMOTE_WORKSPACE=${REMOTE_WORKSPACE:-/home/${USERNAME}/workspace/}
INSTANCE_NAME=${INSTANCE_NAME:-builder-$(cat /proc/sys/kernel/random/uuid)}
ZONE=${ZONE:-us-central1-f}
INSTANCE_ARGS=${INSTANCE_ARGS:---preemptible}

[[ "$REVISION_ID" == "" ]] && REVISION_ID=$(git tag --points-at HEAD )

export
gcloud config set compute/zone ${ZONE}

KEYNAME=builder-key
# TODO Need to be able to detect whether a ssh key was already created
ssh-keygen -t rsa -N "" -f ${KEYNAME} -C ${USERNAME} || true
chmod 400 ${KEYNAME}*

cat > ssh-keys <<EOF
${USERNAME}:$(cat ${KEYNAME}.pub)
EOF

gcloud compute instances create \
       ${INSTANCE_ARGS} ${INSTANCE_NAME} \
       --metadata block-project-ssh-keys=TRUE \
       --metadata-from-file ssh-keys=ssh-keys

trap cleanup EXIT

echo $GITHUB_TOKEN > .gh-token
gcloud compute scp --compress --recurse \
      --verbosity debug \
       $(pwd) ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE} \
       --ssh-key-file=${KEYNAME}

gcloud compute ssh --ssh-key-file=${KEYNAME} \
      --verbosity debug \
       ${USERNAME}@${INSTANCE_NAME} -- "GITHUB_USER=${REPO_OWNER} NAME=${REPO_NAME} TAG=${REVISION_ID} " ${COMMAND}

gcloud compute scp --compress --recurse \
       ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE}*.log $(pwd) \
       --ssh-key-file=${KEYNAME}
