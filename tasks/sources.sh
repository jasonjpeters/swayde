#!/usr/bin/env bash

task::run() {

    ## --- Ensure flathub remote
    if ! flatpak remotes --system | grep -Fxq flathub; then
        log "Adding flathub remote"
        as_root flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    ## --- solopasha/hyprland copr
    copr_enable "solopasha/hyprland"
}
