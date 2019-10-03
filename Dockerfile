FROM ubuntu
ARG SYSTOOLS_VERSION=3.6

RUN apt-get update && \
  apt-get install -y qemu-system-x86 genisoimage curl wget jq git sudo python-setuptools python-pip python-dev build-essential && \
  rm -Rf /var/lib/apt/lists/*  && \
  rm -Rf /usr/share/doc && rm -Rf /usr/share/man  && \
  apt-get clean


RUN wget https://github.com/moshloop/systools/releases/download/${SYSTOOLS_VERSION}/systools.deb && dpkg -i systools.deb
RUN curl https://sdk.cloud.google.com | bash -s --  --disable-prompts --install-dir=/opt
RUN wget https://dl.google.com/go/go1.13.1.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.13.1.linux-amd64.tar.gz && \
  rm go1.13.1.linux-amd64.tar.gz
RUN  pip install ansible awscli azure-cli
RUN install_bin https://releases.hashicorp.com/packer/1.2.4/packer_1.2.4_linux_amd64.zip && \
  install_bin https://github.com/vmware/govmomi/releases/download/v0.18.0/govc_linux_386.gz

