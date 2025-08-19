#!/usr/bin/env bash
# shellcheck shell=bash

# Only define once
if ! declare -F dnf_install >/dev/null 2>&1; then

    dnf_cmd() {
        command -v dnf5 >/dev/null 2>&1 && echo dnf5 || echo dnf
    }

    _dnf_is_installed() {
        local spec="$1"
        rpm -q "$spec" >/dev/null 2>&1 && return 0
        rpm -q --whatprovides "$spec" >/dev/null 2>&1
    }

    # Usage:
    #   dnf_install foo bar baz
    #   dnf_install --dry-run foo bar
    dnf_install() {
        local -a specs=() missing=()
        local dry=0

        # minimal option parse
        while (($#)); do
            case "$1" in
            --dry-run)
                dry=1
                shift
                ;;
            --)
                shift
                break
                ;;
            --*)
                printf 'dnf_install: unknown option: %s\n' "$1" >&2
                return 2
                ;;
            *)
                specs+=("$1")
                shift
                ;;
            esac
        done

        (("$#")) && specs+=("$@")
        ((${#specs[@]})) || return 0

        local s
        for s in "${specs[@]}"; do
            _dnf_is_installed "$s" || missing+=("$s")
        done

        ((${#missing[@]})) || return 0

        if ((dry)); then
            printf '%s\n' "${missing[@]}"
            return 0
        fi

        as_root "$(dnf_cmd)" -y install --setopt=install_weak_deps=False --best "${missing[@]}"
    }

    dnf_upgrade() {
        as_root "$(dnf_cmd)" -y upgrade --refresh "$@"
    }

    dnf_ensure() {
        dnf_install "$@"
        dnf_upgrade "$@"
    }

    # ---------- repo & GPG helpers (generic) ----------

    # Does any imported RPM GPG key's metadata contain <substr> (case-insensitive)?
    rpm_gpg_key_present() { # <substr>
        local needle="$1"
        rpm -qa gpg-pubkey 2>/dev/null |
            xargs -r rpm -qi 2>/dev/null |
            grep -qi -- "$needle"
    }

    # Import a GPG key from URL (safe to re-run).
    rpm_gpg_import() { # <url>
        local url="$1"
        as_root rpm --import "$url"
    }

    # Compute /etc/yum.repos.d/<id>.repo
    repo_path() { # <id>
        printf '/etc/yum.repos.d/%s.repo' "$1"
    }

    # True if repo file exists.
    repo_present() { # <id>
        [[ -f "$(repo_path "$1")" ]]
    }

    # Write a minimal .repo; extra lines may be provided (one per arg).
    # NOTE: pass baseurl with single quotes if you want literal $releasever/$basearch.
    repo_write_simple() { # <id> <name> <baseurl> <gpgkey_url> [enabled(0|1)] [extra...]
        local id="$1" name="$2" baseurl="$3" gpgkey="$4" enabled="${5:-1}"
        shift 5 || true
        local dst
        dst="$(repo_path "$id")"
        {
            echo "[$id]"
            echo "name=$name"
            echo "baseurl=$baseurl"
            echo "enabled=$enabled"
            echo "gpgcheck=1"
            echo "gpgkey=$gpgkey"
            # good defaults
            echo "skip_if_unavailable=True"
            echo "metadata_expire=1h"
            # user-supplied extras
            for line in "$@"; do echo "$line"; done
        } | as_root tee "$dst" >/dev/null
    }

    # Warm metadata for just one repo (nice UX; optional).
    repo_makecache() { # <id>
        as_root "$(dnf_cmd)" -y makecache --disablerepo="*" --enablerepo="$1"
    }

    repo_ensure() { # named args
        local id= name= baseurl= gpgurl= gpgmatch= enabled=1
        local -a extras=()
        while (($#)); do
            case "$1" in
            --id)
                id="$2"
                shift 2
                ;;
            --name)
                name="$2"
                shift 2
                ;;
            --baseurl)
                baseurl="$2"
                shift 2
                ;;
            --gpgkey-url)
                gpgurl="$2"
                shift 2
                ;;
            --gpgkey-match)
                gpgmatch="$2"
                shift 2
                ;;
            --enable)
                enabled=1
                shift
                ;;
            --disable)
                enabled=0
                shift
                ;;
            --extra)
                extras+=("$2")
                shift 2
                ;;
            *)
                printf 'repo_ensure: unknown option %s\n' "$1" >&2
                return 2
                ;;
            esac
        done
        [[ -n "$id" && -n "$name" && -n "$baseurl" && -n "$gpgurl" ]] ||
            {
                printf 'repo_ensure: missing required args\n' >&2
                return 2
            }

        # Import key (always ok), but optionally gate on a substring match to cut noise.
        if [[ -n "$gpgmatch" ]]; then
            rpm_gpg_key_present "$gpgmatch" || rpm_gpg_import "$gpgurl"
        else
            rpm_gpg_import "$gpgurl"
        fi

        repo_present "$id" || repo_write_simple "$id" "$name" "$baseurl" "$gpgurl" "$enabled" "${extras[@]}"
        repo_makecache "$id"
    }

    copr_enabled() {
        local id="${1//\//:}"
        compgen -G "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:${id}*.repo" >/dev/null
    }

    copr_enable() {
        local name="$1"
        copr_enabled "$name" && {
            log "copr $name: present"
            return 0
        }
        dnf_ensure dnf-plugins-core
        as_root "$(dnf_cmd)" -y copr enable "$name"
    }

fi
