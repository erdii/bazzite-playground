#!/usr/bin/bash
# copied from
# https://github.com/ublue-os/hwe/blob/47e360b7ff005764becb2b696aea043d2233e34d/build-initramfs.sh

set -oue pipefail

if [[ "${KERNEL_FLAVOR}" == "surface" ]]; then
    KERNEL_SUFFIX="surface"
else
    KERNEL_SUFFIX=""
fi

if [ ! -f /usr/libexec/rpm-ostree/wrapped/dracut ]; then
    rpm-ostree cliwrap install-to-root /
fi

QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"

/usr/libexec/rpm-ostree/wrapped/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
