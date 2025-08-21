#!/usr/bin/env bash

task::run() {
    local pkgs=(
        neovim
        luarocks
        tree-sitter-cli
        python3-neovim
    )

    copr_enable "agriffis/neovim-nightly"
    dnf_install "${pkgs[@]}"
}
