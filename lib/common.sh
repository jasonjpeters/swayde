#!/usr/bin/env bash
# shellcheck disable=SC1091

set -euo pipefail

CONF_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BIN_HOME="$HOME/.local.bin"
RUNTIME_DIR="$DATA_HOME/swayde"

have() {
    command -v -- "$1" >/dev/null 2>&1
}

log() {
    printf "\033[1;32m[swayde]\033[0m %s\n" "$*"
}

warn() {
    printf "\033[1;33m[warn]\033[0m %s\n" "$*"
}

die() {
    printf "\033[1;31m[fail]\033[0m %s\n" "$*\n"
    exit 1
}

abort() {
    die "requires $1"
}

as_root() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    elif command -v su >/dev/null 2>&1; then
        # run the entire command string as root via su
        su -c "$*"
    else
        die "need root privileges but neither sudo nor su is available" >&2
    fi
}

swayde::ensure_installed() {
    dnf_install "$@"
}
