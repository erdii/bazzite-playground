# Set the disk encryption state (internal, internal+microsd, none, undefined) or show it
encryption state="status":
    #!/usr/bin/bash
    set -euo pipefail
    # Older versions kept the state in this file, carried into the initramfs with
    # an /etc overlay, which `bootc upgrade` refuses to keep
    conf=/etc/bazzite-playground/encryption.conf
    label=bazzite-internal
    karg() {
        tr ' ' '\n' <<<"$1" | sed -n "s/^$2=//p" | tail -n1
    }
    conf_get() {
        [ -r "$conf" ] || return 0
        sed -n "s/^$1=//p" "$conf" | tail -n1
    }
    booted=$(cat /proc/cmdline)
    pending=$(rpm-ostree kargs)
    case "{{ state }}" in
        status)
            echo "Configured state: $(karg "$pending" bazzite.encryption | grep . || conf_get ENCRYPTION | grep . || echo undefined)"
            if [ "$(karg "$pending" bazzite.encryption)" != "$(karg "$booted" bazzite.encryption)" ]; then
                echo "(takes effect after the next reboot)"
            fi
            for mapping in /dev/mapper/crypt-*; do
                [ -e "$mapping" ] || continue
                part=${mapping#/dev/mapper/crypt-}
                [[ $part =~ ^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$ ]] || continue
                echo "Unlocked: $(readlink -f "/dev/disk/by-partuuid/$part") as $mapping"
            done
            if systemctl -q is-active encryption-resume.service; then
                echo "Converting in the background:"
                journalctl -u encryption-resume.service -b -n 1 -o cat --no-pager | tr '\r' '\n' | grep . | tail -n1
            fi
            exit 0
            ;;
        internal | internal+microsd | none | undefined) ;;
        *)
            echo "Usage: ujust encryption [internal|internal+microsd|none|undefined|status]" >&2
            exit 1
            ;;
    esac
    if grep -qwE 'rd\.luks\.(uuid|name)' /proc/cmdline; then
        echo "This system's encryption is managed by the installer (rd.luks on the kernel command line)." >&2
        exit 1
    fi
    internal=$(karg "$pending" bazzite.encryption.internal)
    [ -n "$internal" ] || internal=$(conf_get INTERNAL_PARTUUID)
    if [ -z "$internal" ]; then
        root=$(findmnt -no SOURCE /sysroot | sed 's/\[.*//')
        internal=$(lsblk -nslo TYPE,PARTUUID "$root" | sed -n 's/^part[[:space:]]*//p' | head -n1)
    fi
    boot_uuid=$(findmnt -no UUID /boot)

    # The initramfs finds an encrypted internal partition by this label even
    # without the kernel arguments
    dev=$(readlink -f "/dev/disk/by-partuuid/$internal")
    if [ "$(lsblk -dno FSTYPE "$dev")" = crypto_LUKS ]; then
        dump=$(sudo cryptsetup luksDump "$dev")
        if [[ $dump != *"Label:"*"$label"* ]]; then
            sudo cryptsetup config --label "$label" "$dev" ||
                echo "Could not label $dev yet (conversion in progress?); run this again once it is done." >&2
        fi
    fi

    if [ -n "$(rpm-ostree status --json | jq -r '.deployments[0]["initramfs-etc"] // [] | .[]')" ]; then
        sudo rpm-ostree initramfs-etc --untrack="$conf"
    fi
    sudo rm -f "$conf"

    args=()
    for key in bazzite.encryption bazzite.encryption.internal bazzite.encryption.boot; do
        old=$(karg "$pending" "$key")
        [ -z "$old" ] || args+=(--delete="$key=$old")
    done
    sudo rpm-ostree kargs "${args[@]}" \
        --append="bazzite.encryption={{ state }}" \
        --append="bazzite.encryption.internal=$internal" \
        --append="bazzite.encryption.boot=$boot_uuid"
    echo "Saved bazzite.encryption={{ state }}. Reboot to apply it; converting the data continues"
    echo "in the background after the boot (ujust encryption status)."
