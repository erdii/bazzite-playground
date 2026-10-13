#!/bin/bash
# Steam Deck glue for the 55unl0kr module: plymouth hand-over and DRM wait.

check() {
    require_binaries /usr/libexec/unl0kr-wait-drm || return 1
    return 255
}

depends() {
    echo unl0kr
    return 0
}

install() {
    inst_multiple /usr/libexec/unl0kr-wait-drm cat sleep readlink
    inst_multiple \
        /usr/lib/systemd/system/unl0kr-agent.path.d/plymouth.conf \
        /usr/lib/systemd/system/unl0kr-agent.service.d/plymouth.conf
}
