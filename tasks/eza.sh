#!/usr/bin/env bash

task::run() {
    local pkgs=(
        eza
    )

    copr_enable "alternateved/eza"
    dnf_install "${pkgs[@]}"
}
