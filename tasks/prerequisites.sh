#!/usr/bin/env bash
# shellcheck disable=SC2016

task::run() {
    ## --- Must be Fedora
    [[ -f /etc/fedora-release ]] || abort "Fedora"

    ## --- x86 only
    [[ "$(uname -m)" == "x86_64" ]] || abort "x86_64 only"

    ## --- Must have sudo
    command -v sudo >/dev/null 2>&1 || warn "sudo not found: attempting to install."

    # If sudo is missing, attempt to install it via su/root
    if ! command -v sudo >/dev/null 2>&1; then
        log "sudo not found; attempting to install it as root"

        # Who is the real user to grant wheel to?
        TARGET_USER="${SUDO_USER:-${LOGNAME:-$(id -un)}}"

        if [ "$EUID" -eq 0 ] || command -v su >/dev/null 2>&1; then
            # Export TARGET_USER so it’s visible inside su -c
            TARGET_USER="$TARGET_USER" as_root bash -eu -o pipefail -c '
                # install sudo
                dnf -y install sudo

                # ensure wheel has sudo permissions (create a drop-in if needed)
                if ! grep -Rqs "^[[:space:]]*%wheel[[:space:]]\\+ALL=.*ALL" /etc/sudoers /etc/sudoers.d 2>/dev/null; then
                echo "%wheel ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/00-wheel
                chmod 440 /etc/sudoers.d/00-wheel
                visudo -cf /etc/sudoers >/dev/null
                visudo -cf /etc/sudoers.d/00-wheel >/dev/null
                fi

                # add the invoking user to wheel if not already
                id -nG "$TARGET_USER" | grep -wq wheel || usermod -aG wheel "$TARGET_USER"
            '

            log "sudo installed. Note: new group membership may require re-login."
        else
            die "Neither sudo nor su is available. Please re-run as root."
        fi
    fi

    ## -- Must not have Gnome or KDE (might not be a prereq)
    rpm -q gnome-shell &>/dev/null && abort "Gnome not be installed."
    rpm -q plasma-desktop &>/dev/null && abort "KDE not be installed."

    log "Prerequisites OK"
}
