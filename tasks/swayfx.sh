#!/usr/bin/env bash
# shellcheck disable=SC2329

task::run() {
    copr_enable "swayfx/swayfx"

    # check if sway is already swayfx
    if sway --version 2>/dev/null | grep -qi swayfx; then
        log "swayfx already installed, skipping swap"
        return 0
    fi

    as_root dnf swap -y sway swayfx \
        --allowerasing \
        --setopt=protected_packages=
}
