#!/bin/bash

# Guard so sourcing multiple times is safe
if ! declare -F flatpak_installed >/dev/null 2>&1; then

    _fpk_die() {
        printf 'flatpak: %s\n' "$*" >&2
        return 1
    }
    _fpk_cmd() { command -v flatpak >/dev/null 2>&1; }

    # Check install by app ID (user/system/any)
    flatpak_installed() {
        local id="$1" scope="${2:-any}"
        case "$scope" in
        user) flatpak list --user --app --columns=application | grep -Fxq "$id" ;;
        system) flatpak list --system --app --columns=application | grep -Fxq "$id" ;;
        any) flatpak list --app --columns=application | grep -Fxq "$id" ;;
        *)
            printf 'bad scope\n' >&2
            return 2
            ;;
        esac
    }

    # Ensure the flatpak binary exists (Fedora-friendly)
    fpk_ensure_flatpak() {
        _fpk_cmd || as_root "$(dnf_cmd)" install -y flatpak
    }

    # Ensure a remote exists (defaults to flathub) in chosen scope
    fpk_ensure_remote() {
        local scope="${1:-system}" name="${2:-flathub}"
        local url="${3:-https://dl.flathub.org/repo/flathub.flatpakrepo}"
        local -a flag=()

        case "$scope" in
        user) flag=(--user) ;;
        system) flag=(--system) ;;
        *) _fpk_die "scope must be user|system" ;;
        esac

        if ! flatpak remotes "${flag[@]}" --columns=name | grep -Fxq "$name"; then
            if [[ "$scope" == "system" ]]; then
                as_root flatpak remote-add --if-not-exists "${flag[@]}" "$name" "$url"
            else
                flatpak remote-add --if-not-exists "${flag[@]}" "$name" "$url"
            fi
        fi
    }

    # Install missing app IDs
    # Usage: fpk_install [--scope=user|system] [--remote=name] [--dry-run] APP_ID...
    fpk_install() {
        local scope="system" remote="flathub" dry=0
        local -a ids=() missing=() scope_flag=()

        while (($#)); do
            case "$1" in
            --scope=*)
                scope="${1#*=}"
                shift
                ;;
            --remote=*)
                remote="${1#*=}"
                shift
                ;;
            --dry-run)
                dry=1
                shift
                ;;
            --)
                shift
                break
                ;;
            --*)
                printf 'fpk_install: unknown option: %s\n' "$1" >&2
                return 2
                ;;
            *)
                ids+=("$1")
                shift
                ;;
            esac
        done
        (("$#")) && ids+=("$@")
        ((${#ids[@]})) || return 0

        fpk_ensure_flatpak
        case "$scope" in
        user) scope_flag=(--user) ;;
        system) scope_flag=(--system) ;;
        *) _fpk_die "scope must be user|system" ;;
        esac
        fpk_ensure_remote "$scope" "$remote"

        local id
        for id in "${ids[@]}"; do
            flatpak_installed "$id" any || missing+=("$id")
        done
        ((${#missing[@]})) || return 0

        if ((dry)); then
            printf '%s\n' "${missing[@]}"
            return 0
        fi

        if [[ "$scope" == "system" ]]; then
            as_root flatpak install -y --noninteractive "${scope_flag[@]}" "$remote" "${missing[@]}"
        else
            flatpak install -y --noninteractive "${scope_flag[@]}" "$remote" "${missing[@]}"
        fi
    }

fi
