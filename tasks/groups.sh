#!/usr/bin/env bash
# shellcheck disable=SC2329

task::run() {
    local grps=(
        design-suite
        development-tools
        libreoffice
        office
        sound-and-video
        system-tools
        text-internet
    )

    for grp in "${grps[@]}"; do
        as_root "$(dnf_cmd)" group install -y "$grp"
    done
}
