#!/bin/bash
# Brings disks to the encryption state of /etc/bazzite-playground/encryption.conf
# (carried into the initramfs by `ujust encryption`), see encryption-converge.

check() {
    require_binaries cryptsetup keyctl blockdev btrfs e2fsck resize2fs dumpe2fs \
        /usr/libexec/encryption-converge || return 1
    return 255
}

depends() {
    echo systemd crypt btrfs
    return 0
}

install() {
    inst_multiple cryptsetup keyctl blockdev blkid btrfs e2fsck resize2fs dumpe2fs \
        mount umount mkdir readlink sed tr sync udevadm \
        /usr/libexec/encryption-converge
    inst_simple /usr/lib/systemd/system/encryption-converge.service
    $SYSTEMCTL -q --root "$initdir" enable encryption-converge.service
}
