#!/usr/bin/env bash
# shellcheck disable=SC2329

task::run() {
    copr_enable "swayfx/swayfx"
    as_root dnf swap -y sway swayfx --allowerasing --setopt=protected_packages=
}
