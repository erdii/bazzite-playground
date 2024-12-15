#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

# Enable sigstore validation for ostree images from ghcr.io/erdii.
jq '.transports.docker["ghcr.io/erdii"] = {"type": "sigstoreSigned","keyPath":"/etc/pki/containers/erdii.pub","signedIdentity":{"type":"matchRepository"}}' /etc/containers/policy.json > /etc/containers/policy.json.2
mv /etc/containers/policy.json.2 /etc/containers/policy.json

curl -Lo /etc/yum.repos.d/_copr_erdii-bazzite-playground.repo \
    https://copr.fedorainfracloud.org/coprs/erdii/bazzite-playground/repo/fedora-"${RELEASE}"/erdii-bazzite-playground-fedora-"${RELEASE}".repo

rpm-ostree install \
    unl0kr-0.0.git.17.fafd46ec-1.fc41.x86_64 \
    unl0kr-dracut-0.0.git.17.fafd46ec-1.fc41.x86_64 \
    golang \
    fedora-packager \
    fedora-review \
    rpkg \
    git \
    systemd-rpm-macros \
    systemd-devel \
    gcc \
    wget \
    meson \
    ninja-build \
    inih-devel \
    libinput-devel \
    libgudev \
    libxkbcommon-devel \
    libdrm-devel \
    scdoc

KERNEL_FLAVOR="main" /tmp/build-initramfs.sh
