#!/bin/bash
# One-time in-place encryption of a partition named by rd.encrypt=, see
# luks-encrypt-init.

check() {
    require_binaries cryptsetup blockdev btrfs /usr/libexec/luks-encrypt-init || return 1
    return 255
}

depends() {
    echo systemd crypt btrfs
    return 0
}

install() {
    inst_multiple cryptsetup blockdev btrfs blkid sed tr tail /usr/libexec/luks-encrypt-init
    inst_simple /usr/lib/systemd/system/luks-encrypt-init.service
    $SYSTEMCTL -q --root "$initdir" enable luks-encrypt-init.service
}
