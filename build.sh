#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

curl -Lo /etc/yum.repos.d/_copr_erdii-bazzite-playground.repo \
    https://copr.fedorainfracloud.org/coprs/erdii/bazzite-playground/repo/fedora-"${RELEASE}"/erdii-bazzite-playground-fedora-"${RELEASE}".repo

rpm-ostree install \
    unl0kr-2.0.3-1.fc40.x86_64 \
    unl0kr-dracut-2.0.3-1.fc40.x86_64 \
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
