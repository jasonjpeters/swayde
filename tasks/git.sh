#!/usr/bin/env bash
# shellcheck disable=SC2329

task::run() {
    local pkgs=(
        git
        lazygit
    )

    copr_enable "dejan/lazygit"
    dnf_install "${pkgs[@]}"

    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status

    git config --global init.defaultBranch main
    git config --global pull.rebase true

    # --- Check git user config ---
    local name email

    name="$(git config --global user.name || true)"
    email="$(git config --global user.email || true)"

    if [[ -z "$name" ]]; then
        name="$(gum input --placeholder "Your Name")"
        if [[ -n "$name" ]]; then
            git config --global user.name "$name"
        fi
    fi

    if [[ -z "$email" ]]; then
        email="$(gum input --placeholder "you@example.com")"
        if [[ -n "$email" ]]; then
            git config --global user.email "$email"
        fi
    fi
}
