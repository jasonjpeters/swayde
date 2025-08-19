#!/usr/bin/env bash

task::run() {
    local pkgs=(
        bat
        btop
        cascadia-code-nf-fonts
        curl
        dnf-plugins-core
        doctl
        fastfetch
        fd-find
        fira-code-fonts
        flatpak
        fontawesome-fonts-all
        foot-terminfo
        fzf
        git
        gum
        gvfs
        gvfs-archive
        gvfs-client
        gvfs-fuse
        gvfs-mtp
        gvfs-nfs
        gvfs-smb
        hellwal
        httpie
        ImageMagick
        jq
        kanshi
        mariadb
        plocate
        ripgrep
        rsync
        shfmt
        tmux
        unzip
        vips-tools
        wdisplays
        wget
        whois
        xmlstarlet
        zip
        vim-default-editor
        zsh
    )

    dnf_install "${pkgs[@]}"

    as_root dnf remove -y nano # go away
}
