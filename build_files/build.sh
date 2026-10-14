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

### unl0kr: touchscreen LUKS unlock in the initramfs

dnf5 install -y /ctx/rpms/*.rpm

systemctl enable encryption-resume.service encryption-sdcard-mount.service

# The base image ships a prebuilt initramfs; rebuild it so it picks up unl0kr
# (90-unl0kr.conf) with the same flags as bazzite/build_files/build-initramfs.
KVER=$(ls /usr/lib/modules)
dracut --no-hostonly --reproducible --zstd --add ostree --add fido2 --kver "$KVER" \
    -f "/usr/lib/modules/$KVER/initramfs.img"
chmod 0600 "/usr/lib/modules/$KVER/initramfs.img"
