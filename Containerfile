# unl0kr (touchscreen LUKS unlock) RPMs: buffybox 3.6.0 Fedora packaging + our patches
FROM registry.fedoraproject.org/fedora:44 AS unl0kr-build
ARG UNL0KR_PKG_REV=b801b827a30d5124aee288b641e39c0955288f88
COPY unl0kr/patches/ /patches/
RUN dnf -y --setopt=install_weak_deps=False install \
        git rpm-build rpmdevtools dnf-plugins-core meson gcc curl && \
    git clone https://github.com/jaredbartimus/buffybox-unl0kr-fedora /pkg && \
    git -C /pkg checkout "$UNL0KR_PKG_REV" && \
    cd /pkg && rpmdev-setuptree && top=$(rpmbuild --eval %_topdir) && \
    scripts/fetch-sources.sh "$top/SOURCES" && \
    cp ARCHITECTURE-SECURITY.md dracut/module-setup.sh /patches/*.patch "$top/SOURCES/" && \
    sed -i 's/^Patch0: .*/&\nPatch1:         0002-unl0kr-rotate-ui-from-panel-orientation.patch\nPatch2:         0004-indev-combined-devices-and-rotated-motion.patch/' buffybox-unl0kr.spec && \
    sed -i "s/^mv lvgl-%{lvgl_commit} lvgl$/&\npatch -p1 -i %{_sourcedir}\/0003-lvgl-drm-software-rotation.patch/" buffybox-unl0kr.spec && \
    dnf -y builddep buffybox-unl0kr.spec && \
    rpmbuild -bb buffybox-unl0kr.spec && \
    mkdir /out && cp "$top"/RPMS/x86_64/unl0kr-3*.rpm "$top"/RPMS/x86_64/unl0kr-agent-3*.rpm \
        "$top"/RPMS/x86_64/unl0kr-dracut-3*.rpm /out/

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files
COPY --from=unl0kr-build /out /rpms

# Base Image
FROM ghcr.io/ublue-os/bazzite-deck-gnome:stable
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:testing
# FROM ghcr.io/ublue-os/aurora:stable
# FROM ghcr.io/ublue-os/bluefin-nvidia-open:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:44
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
