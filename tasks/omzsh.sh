#!/usr/bin/env bash
# shellcheck disable=SC2088
# shellcheck disable=SC2016

task::run() {
    command -v zsh >/dev/null 2>&1 || {
        log "zsh not found on PATH"
        return 1
    }
    command -v curl >/dev/null 2>&1 || {
        log "curl not found on PATH"
        return 1
    }

    local ZDOT="$HOME/.zshrc"
    local desired='source "$HOME/.config/omzsh/rc"'

    if [[ -e "$ZDOT" ]]; then
        # replace if it's not exactly our one-liner
        if ! grep -qxF "$desired" "$ZDOT" 2>/dev/null || [[ $(wc -l <"$ZDOT") -ne 1 ]]; then
            # backup to swayde backup area
            local STATE_BASE="${XDG_STATE_HOME:-$HOME/.local/state}"
            local RUN_ID="${SWAYDE_BACKUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
            local BROOT="${SWAYDE_BACKUP_DIR:-$STATE_BASE/swayde/backups}/$RUN_ID/home/${USER}"
            mkdir -p "$BROOT"
            cp -a "$ZDOT" "$BROOT/.zshrc"
            log "backup: $ZDOT -> $BROOT/.zshrc"

            printf '%s\n' "$desired" >"$ZDOT"
            log "wrote shim to $ZDOT"
        else
            log "~/.zshrc already shims to .config/omzsh/rc"
        fi
    else
        printf '%s\n' "$desired" >"$ZDOT"
        log "created shim $ZDOT"
    fi

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        RUNZSH=no CHSH=yes KEEP_ZSHRC=yes \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            -- --unattended --keep-zshrc
        log "oh-my-zsh installed"
    else
        log "~/.oh-my-zsh already present; skipping installer"
    fi
}
