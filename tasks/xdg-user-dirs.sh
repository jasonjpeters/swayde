#!/usr/bin/env bash
# shellcheck disable=SC2016

task::run() {
    local file="$CONF_HOME/user-dirs.dirs"
    local desired='XDG_PROJECTS_DIR="$HOME/Projects"'

    dnf_install xdg-user-dirs
    mkdir -p "$CONF_HOME"
    if [[ ! -f "$file" ]]; then
        xdg-user-dirs-update || true
        [[ -f "$file" ]] || { printf '# created by swayde\n' >"$file"; }
        log "created $file"
    fi

    if grep -qE '^[[:space:]]*XDG_PROJECTS_DIR=' "$file"; then
        log "XDG_PROJECTS_DIR already present in $file; skip append"
    else
        local STATE_BASE="${XDG_STATE_HOME:-$HOME/.local/state}"
        local RUN_ID="${SWAYDE_BACKUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
        local BACKUP_ROOT="${SWAYDE_BACKUP_DIR:-$STATE_BASE/swayde/backups}"
        local dst="$BACKUP_ROOT/$RUN_ID/${file#/}"
        mkdir -p "$(dirname "$dst")"
        cp -a "$file" "$dst"
        log "backup: $file -> $dst"

        printf '%s\n' "$desired" >>"$file"
        log "added to $file: $desired"
    fi

    mkdir -p "$HOME/Projects"
}
