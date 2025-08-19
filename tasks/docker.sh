#!/usr/bin/env bash

task::run() {
    local pkgs=(
        docker-ce
        docker-ce-cli
        containerd.io
        docker-buildx-plugin
        docker-compose-plugin
        lazydocker
    )

    DOCKER_REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
    DOCKER_REPO_FILE="/etc/yum.repos.d/docker-ce.repo"
    [ -f "$DOCKER_REPO_FILE" ] || as_root dnf-3 config-manager --add-repo "$DOCKER_REPO_URL"

    copr_enable "atim/lazydocker"
    dnf_install "${pkgs[@]}"

    as_root systemctl enable --now docker || true
    local u="${SUDO_USER:-$USER}"
    id -nG "$u" | grep -qw docker || {
        as_root usermod -aG docker "$u"
    }
}
