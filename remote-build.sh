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

gcloud compute scp --compress --recurse \
      --verbosity debug \
       $(pwd) ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE} \
       --ssh-key-file=${KEYNAME}

gcloud compute ssh --ssh-key-file=${KEYNAME} \
      --verbosity debug \
       ${USERNAME}@${INSTANCE_NAME} -- "export GITHUB_USER=${_REPO_OWNER} && export NAME=${REPO_NAME} && exportTAG=${REVISION_ID} && " ${COMMAND}

gcloud compute scp --compress --recurse \
       ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE}*.log $(pwd) \
       --ssh-key-file=${KEYNAME}
