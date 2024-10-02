#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"

rpm-ostree install golang

rpm-ostree install git \
    systemd-rpm-macros \
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

# curl -Lo /etc/yum.repos.d/_copr_erdii-bazzite-playground.repo https://copr.fedorainfracloud.org/coprs/erdii/bazzite-playground/repo/fedora-"${RELEASE}"/erdii-bazzite-playground-fedora-"${RELEASE}".repo

# rpm-ostree install unl0kr
