#!/bin/bash

set -e

# Always delete instance after attempting build
function cleanup {
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[${timestamp}] Removing instance ${INSTANCE_NAME}"
  gcloud compute instances delete ${INSTANCE_NAME} --quiet --delete-disks=all
}

# Configurable parameters
[ -z "$COMMAND" ] && echo "Need to set COMMAND" && exit 1;

USERNAME=${USERNAME:-admin}
REMOTE_WORKSPACE=${REMOTE_WORKSPACE:-/home/${USERNAME}/workspace/}
INSTANCE_NAME=${INSTANCE_NAME:-builder-$(cat /proc/sys/kernel/random/uuid)}
ZONE=${ZONE:-us-central1-f}
NESTED_VIRT_NAME=$(gcloud compute images list --no-standard-images --filter 'family:nested-virt-20-04' --format 'value(name)')
INSTANCE_ARGS="$INSTANCE_ARGS --image $NESTED_VIRT_NAME --preemptible"

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
       --machine-type=n2-standard-2 \
       --boot-disk-size=50 \
       --metadata block-project-ssh-keys=TRUE \
       --metadata-from-file ssh-keys=ssh-keys

function wait_for_ssh {
    echo "Attempting to SSH to Builder machine..."
    attempt=1
    while (( $attempt <= 5 )); do
      gcloud compute ssh  --ssh-key-file=${KEYNAME} ${USERNAME}@${INSTANCE_NAME} --ssh-flag="-Nf" && EC=$?|| EC=$? && true
      case ${EC} in
          (0) echo "Success after ${attempt} try"; break ;;
          (*) echo "${attempt} of 5 failed attempts, Builder SSH Machine not ready yet, waiting 2 seconds..." ;;
      esac
      sleep 2s
      ((attempt+=1))
    done
}

trap cleanup EXIT

wait_for_ssh

echo $GITHUB_TOKEN > .gh-token
gcloud compute scp --compress --recurse \
      --verbosity debug \
       $(pwd) ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE} \
       --ssh-key-file=${KEYNAME}

gcloud compute ssh --ssh-key-file=${KEYNAME} \
      --verbosity debug \
       ${USERNAME}@${INSTANCE_NAME} -- "${COMMAND} ${BUILD_STEP} ${TEST_TEMPLATE}"

gcloud compute scp --compress --recurse \
       ${USERNAME}@${INSTANCE_NAME}:${REMOTE_WORKSPACE}*.log $(pwd) \
       --ssh-key-file=${KEYNAME} || echo "No logs found"
