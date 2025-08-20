#!/usr/bin/env bash
# shellcheck disable=SC2329
# shellcheck disable=SC2016

task::run() {
  local pkgs=(
    incus
    incus-tools
  )

  dnf_install "${pkgs[@]}"

  # Incus is socket-activated
  as_root systemctl daemon-reload || true
  as_root systemctl enable --now incus.socket || true

  # target user (prefers the invoking sudo user)
  local u="${SUDO_USER:-$USER}"

  # ensure incus-admin group membership (no-op if already a member)
  if getent group incus-admin >/dev/null 2>&1; then
    if ! id -nG "$u" | grep -qw incus-admin; then
      as_root usermod -aG incus-admin "$u"
      log "added $u to incus-admin (re-login normally required; we will spawn a fresh process instead)"
    fi
  else
    warn "group 'incus-admin' not found (is incus fully installed?); skipping usermod"
  fi

  # ensure subuid/subgid entries for root + user (idempotent)
  local SUB_START="${SWAYDE_SUBID_START:-1000000}"
  local SUB_COUNT="${SWAYDE_SUBID_COUNT:-65536}"

  _ensure_subid() { # <name> <start> <count> <file>
    local name="${1:?_ensure_subid: name missing}"
    local start="${2:?_ensure_subid: start missing}"
    local count="${3:?_ensure_subid: count missing}"
    local file="${4:?_ensure_subid: file missing}"
    local line="${name}:${start}:${count}"
    [[ -f "$file" ]] || : >"$file"
    if ! grep -qE "^${name}:" "$file" 2>/dev/null; then
      printf '%s\n' "$line" | as_root tee -a "$file" >/dev/null
      log "added to $file: $line"
    elif grep -qE "^${name}:$start:$count$" "$file"; then
      log "$file already contains: $line"
    else
      local existing
      existing="$(grep -E "^${name}:" "$file" | head -n1 || true)"
      warn "$file already has: $existing (leaving as-is)"
    fi
  }

  _ensure_subid root "$SUB_START" "$SUB_COUNT" /etc/subuid
  _ensure_subid root "$SUB_START" "$SUB_COUNT" /etc/subgid
  _ensure_subid "$u" "$SUB_START" "$SUB_COUNT" /etc/subuid
  _ensure_subid "$u" "$SUB_START" "$SUB_COUNT" /etc/subgid

  # spawn a child that *sees* new incus-admin membership immediately
  _run_as_incus_admin() { # <user> -- <cmd...>
    local _user="${1:?user missing}"
    shift
    [[ "${1:-}" == "--" ]] && shift
    if command -v setpriv >/dev/null 2>&1; then
      as_root setpriv --reuid "$_user" --regid incus-admin --init-groups --reset-env -- "$@"
    elif command -v sg >/dev/null 2>&1 && command -v runuser >/dev/null 2>&1; then
      as_root sg incus-admin -c "runuser -u $_user -- $*"
    else
      as_root sudo -u "$_user" -g incus-admin -- "$@"
    fi
  }

  # guard: treat daemon as initialized if default profile + network + storage exist
  _incus_is_initialized() { # runs as current user
    local y
    y="$(incus profile show default 2>/dev/null)" || return 1
    grep -qE '^[[:space:]]+devices:' <<<"$y" || return 1
    grep -qE '^[[:space:]]+root:[[:space:]]*$' <<<"$y" || return 1
    grep -qE '^[[:space:]]+type:[[:space:]]+disk' <<<"$y" || return 1
    grep -qE '^[[:space:]]+eth0:[[:space:]]*$' <<<"$y" || return 1
    grep -qE '^[[:space:]]+type:[[:space:]]+nic' <<<"$y" || return 1
    incus network show incusbr0 >/dev/null 2>&1 || return 1
    incus storage show default >/dev/null 2>&1 || return 1
    return 0
  }

  # apply your static preseed only if needed
  _incus_init_with_preseed() { # <user>
    local _user="${1:?user missing}"

    as_root systemctl is-active --quiet incus.socket || as_root systemctl start incus.socket

    if _run_as_incus_admin "$_user" -- bash -c '
            _incus_is_initialized() {
              local y; y="$(incus profile show default 2>/dev/null)" || return 1
              grep -qE "^[[:space:]]+devices:" <<<"$y" || return 1
              grep -qE "^[[:space:]]+root:[[:space:]]*$" <<<"$y" || return 1
              grep -qE "^[[:space:]]+type:[[:space:]]+disk" <<<"$y" || return 1
              grep -qE "^[[:space:]]+eth0:[[:space:]]*$" <<<"$y" || return 1
              grep -qE "^[[:space:]]+type:[[:space:]]+nic" <<<"$y" || return 1
              incus network show incusbr0 >/dev/null 2>&1 || return 1
              incus storage show default   >/dev/null 2>&1 || return 1
              return 0
            }
            _incus_is_initialized
        '; then
      log "Incus already initialized; skipping --preseed."
      return 0
    fi

    # apply fixed YAML
    if _run_as_incus_admin "$_user" -- bash -s <<'BASH'; then
set -euo pipefail
cat <<'EOF' | incus admin init --preseed
config:
  core.https_address: '[::]:8443'
networks:
- name: incusbr0
  type: bridge
  config:
    ipv4.address: 10.10.10.1/24
    ipv6.address: none
storage_pools:
- name: default
  driver: dir
profiles:
- name: default
  description: ""
  devices:
    eth0:
      name: eth0
      network: incusbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
EOF
BASH
      log "Incus initialized via preseed."
    else
      warn "Incus preseed failed; attempting repair/ensure…"

      # --- Repair path
      _run_as_incus_admin "$_user" -- bash -lc '
                set -euo pipefail
                if ! incus network show incusbr0 >/dev/null 2>&1; then
                  incus network create incusbr0 --type=bridge ipv4.address=10.10.10.1/24 ipv6.address=none || true
                  incus network set incusbr0 ipv4.firewall false || true
                  incus network set incusbr0 ipv6.firewall false || true
                fi
                incus storage show default >/dev/null 2>&1 || incus storage create default dir || true
                if ! incus profile show default | grep -q "network: incusbr0"; then
                  incus profile device add default eth0 nic name=eth0 network=incusbr0 || true
                fi
                if ! incus profile show default | grep -q "^\\s\\+root:"; then
                  incus profile device add default root disk path=/ pool=default || true
                fi
            '

      # verify after repair
      if _run_as_incus_admin "$_user" -- bash -c '
                incus network show incusbr0 >/dev/null 2>&1 &&
                incus storage show default >/dev/null 2>&1 &&
                incus profile show default | grep -q "network: incusbr0" &&
                incus profile show default | grep -q "type: disk"
            '; then
        log "Incus repaired and ready."
      else
        warn "Incus still not healthy; check: incus network list && incus profile show default"
        return 1
      fi
    fi
  }

  # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # DO THE THING: run the preseed step now
  _incus_init_with_preseed "$u"
  # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  # optional: brief post-init log
  _run_as_incus_admin "$u" -- bash -lc '
        incus version || true
        incus profile list || true
        incus network list || true
        incus storage list || true
    '
}
