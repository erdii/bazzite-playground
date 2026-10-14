# Set the disk encryption state (internal, internal+microsd, none, undefined) or show it
encryption state="status":
    #!/usr/bin/bash
    set -euo pipefail
    conf=/etc/bazzite-playground/encryption.conf
    conf_get() {
        [ -r "$conf" ] || return 0
        sed -n "s/^$1=//p" "$conf" | tail -n1
    }
    case "{{ state }}" in
        status)
            echo "Configured state: $(conf_get ENCRYPTION | grep . || echo undefined)"
            for mapping in /dev/mapper/crypt-*; do
                [ -e "$mapping" ] || continue
                part=${mapping#/dev/mapper/crypt-}
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
    # The /etc overlay used below does not work together with it
    if rpm-ostree status --json | jq -e '.deployments[0]["regenerate-initramfs"]' >/dev/null; then
        echo "Local initramfs regeneration is enabled (rpm-ostree initramfs --enable). Disable it, or" >&2
        echo "include $conf yourself: sudo rpm-ostree initramfs --enable --arg=-I --arg=$conf" >&2
        exit 1
    fi
    internal=$(conf_get INTERNAL_PARTUUID)
    if [ -z "$internal" ]; then
        root=$(findmnt -no SOURCE /sysroot | sed 's/\[.*//')
        internal=$(lsblk -nslo TYPE,PARTUUID "$root" | sed -n 's/^part[[:space:]]*//p' | head -n1)
    fi
    boot_uuid=$(findmnt -no UUID /boot)
    sudo install -d /etc/bazzite-playground
    printf 'ENCRYPTION=%s\nINTERNAL_PARTUUID=%s\nBOOT_UUID=%s\n' "{{ state }}" "$internal" "$boot_uuid" |
        sudo tee "$conf" >/dev/null
    # The initramfs reads the state from its own copy of the file
    sudo rpm-ostree initramfs-etc --track="$conf" --force-sync
    echo "Saved ENCRYPTION={{ state }}. Reboot to apply it; converting the data continues"
    echo "in the background after the boot (ujust encryption status)."
