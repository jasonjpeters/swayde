#!/usr/bin/env bash

task::run() {
    local pkgs=(
        nodejs
        nodejs-npm
    )

    dnf_install "${pkgs[@]}"

    if [ ! -d "$HOME/.npm-global" ]; then
        mkdir -p "$HOME/.npm-global/lib"
    fi

    npm config set prefix "$HOME/.npm-global"
    export PATH=~/.npm-global/bin:$PATH

    ## Global npm packages
    npm install -g \
        neovim \
        @automattic/vip \
        @wordpress/create-block \
        @wordpress/env
}
