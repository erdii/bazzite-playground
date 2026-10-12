#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Enable sigstore validation for images from ghcr.io/erdii/bazzite-playground.
jq '.transports.docker["ghcr.io/erdii/bazzite-playground"] = [{
        "type": "sigstoreSigned",
        "keyPath": "/etc/pki/containers/erdii.pub",
        "signedIdentity": {
            "type": "matchRepository"
        }
    }]' /etc/containers/policy.json > /etc/containers/policy.json.new
mv /etc/containers/policy.json.new /etc/containers/policy.json

curl -Lo /etc/yum.repos.d/mullvad.repo https://repository.mullvad.net/rpm/stable/mullvad.repo
dnf5 install -y mullvad-vpn golang git
# Don't leave the third-party repo enabled in the image.
rm /etc/yum.repos.d/mullvad.repo

### unl0kr: touchscreen LUKS unlock in the initramfs

dnf5 install -y /ctx/rpms/*.rpm

# The base image ships a prebuilt initramfs; rebuild it so it picks up unl0kr
# (90-unl0kr.conf) with the same flags as bazzite/build_files/build-initramfs.
KVER=$(ls /usr/lib/modules)
dracut --no-hostonly --reproducible --zstd --add ostree --add fido2 --kver "$KVER" \
    -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
