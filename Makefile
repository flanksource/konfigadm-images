
.PHONY: setup
setup:
	apt-get install -y qemu-system-x86 kpart python-pexpec python-serial libguestfs-tools
  gsutil cp gs://moshloop-image-builder/VMware-ovftool-4.3.0-12320924-lin.x86_64.bundle .
  chmod +x VMware-ovftool-4.3.0-12320924-lin.x86_64.bundle
  ./VMware-ovftool-4.3.0-12320924-lin.x86_64.bundle--eulas-agreed --required
