# Kubernetes Image Pipelines

[![Build status](https://ci.appveyor.com/api/projects/status/tpwojba92e48w36m?svg=true)](https://ci.appveyor.com/project/moshloop/konfigadm-images)

This repository contains a pipeline for building kubernetes images [konfigadm](https://github.com/moshloop/konfigadm), Builds run on appveyor Ubuntu1804 images which support nested virtualization. Images are uploaded to Github Releases

The goal is to publish images for every Kubernetes, OS and CRI version for easy consumption.

Images can be further customized by either running `konfigadm build-image --image` with the published image, or rebuilding from source and extending the `k8s-docker.yml` file using any valid konfigadm declaration

### Operating Systems

- [x] Ubuntu 18.04
- [x] Ubuntu 16.04
- [x] Debian 9
- [x] Centos 7
- [ ] Fedora 29 - Currently failing and quarantined
- [ ] Fedora 30
- [ ] Amazon Linux 2

### Kubernetes Versions

- [ ] v1.15.0
- [x] v1.14.2
- [x] v1.13.6

### Container Runtimes

- [x] Docker CE
- [ ] containerd
- [ ] CRI-O
