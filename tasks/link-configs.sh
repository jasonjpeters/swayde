#!/usr/bin/env bash
# shellcheck disable=SC2012
# shellcheck disable=SC2115
# Symlink swayde configs into ~/.config and apply optional extras.
# Backups go under $XDG_STATE_HOME/swayde/backups/<run-id>/…

task::run() {
    local policy="${SWAYDE_LINK_POLICY:-backup}" # backup|replace|skip
    local root="$RUNTIME_DIR/config"
    [[ -d "$root" ]] || {
        log "TASK link-configs: no config/; skip"
        return
    }

    # --- backup area per run ---
    local STATE_BASE="${XDG_STATE_HOME:-$HOME/.local/state}"
    local BACKUP_ROOT="${SWAYDE_BACKUP_DIR:-$STATE_BASE/swayde/backups}"
    local RUN_ID="${SWAYDE_BACKUP_RUN_ID:-$(date +%Y%m%d-%H%M%S)}"
    local BACKUP_RUN="$BACKUP_ROOT/$RUN_ID"
    mkdir -p "$BACKUP_RUN"

    # optional: prune old runs (keep newest N)
    local KEEP="${SWAYDE_BACKUP_KEEP:-10}"
    if [[ "$KEEP" =~ ^[0-9]+$ ]] && [[ -d "$BACKUP_ROOT" ]]; then
        mapfile -t _runs < <(ls -1 "$BACKUP_ROOT" 2>/dev/null | sort)
        local prune_count=$((${#_runs[@]} - KEEP))
        if ((prune_count > 0)); then
            local i
            for ((i = 0; i < prune_count; i++)); do
                rm -rf -- "$BACKUP_ROOT/${_runs[$i]}"
                log "prune backups: $BACKUP_ROOT/${_runs[$i]}"
            done
        fi
    fi

    _backup_item() { # <dst>
        local dst="$1"
        local rel="${dst#/}" # strip leading slash
        local bkp="$BACKUP_RUN/$rel"
        mkdir -p "$(dirname "$bkp")"
        mv -f -- "$dst" "$bkp"
        log "backup: $dst -> $bkp"
    }

    _link_one() { # <src> <dst>
        local src="$1" dst="$2"

        # already linked to correct target?
        if [[ -L "$dst" ]]; then
            local cur want
            cur="$(readlink -f "$dst" 2>/dev/null || true)"
            want="$(readlink -f "$src" 2>/dev/null || true)"
            if [[ -n "$cur" && "$cur" == "$want" ]]; then
                log "link ok: $dst"
                return 0
            fi
            case "$policy" in
            backup) _backup_item "$dst" ;;
            replace)
                rm -f -- "$dst"
                log "replace link: $dst"
                ;;
            skip)
                log "skip (link points elsewhere): $dst"
                return 0
                ;;
            *)
                log "unknown policy '$policy' (use backup|replace|skip)"
                return 2
                ;;
            esac
        elif [[ -e "$dst" ]]; then
            # real file/dir in the way
            case "$policy" in
            backup) _backup_item "$dst" ;;
            replace)
                rm -rf -- "$dst"
                log "replace: $dst (removed)"
                ;;
            skip)
                log "skip (exists): $dst"
                return 0
                ;;
            *)
                log "unknown policy '$policy'"
                return 2
                ;;
            esac
        else
            mkdir -p "$(dirname "$dst")"
        fi

        ln -sfn -- "$src" "$dst"
        log "link: $dst -> $src"
    }

    # 1) ~/.config: link each top-level dir under config/*
    find "$root" -mindepth 1 -maxdepth 1 -type d -print0 |
        while IFS= read -r -d '' src; do
            _link_one "$src" "$HOME/.config/$(basename "$src")"
        done

    # 2) extras map (optional): "relative/or/abs/src -> ~/dest/path"
    local map="$RUNTIME_DIR/links.extra"
    [[ -f "$map" ]] || return 0

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]] && continue
        local left="${line%%->*}" right="${line#*->}"
        left="$(echo "$left" | xargs)"
        right="$(echo "$right" | xargs)"
        eval "right=\"$right\"" # expand ~ in destination
        [[ "$left" = /* ]] || left="$RUNTIME_DIR/$left"
        _link_one "$left" "$right"
    done <"$map"
}
