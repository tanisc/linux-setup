#!/usr/bin/env bash
# apt: system update/upgrade + manifest-driven package install (restore-only).

restore_packages_apt() {
    require_sudo

    log "apt-get update..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

    log "apt-get full-upgrade (non-interactive)..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y

    local manifest="$SCRIPT_DIR/manifests/packages-apt.list"
    if [[ -s "$manifest" ]]; then
        mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$manifest")
        if [[ ${#pkgs[@]} -gt 0 ]]; then
            log "Installing ${#pkgs[@]} apt package(s) from manifest..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
        else
            log "packages-apt.list has no entries, skipping install."
        fi
    else
        warn "manifests/packages-apt.list not found or empty, skipping package install."
    fi

    # kubuntu-desktop pulls in sddm, but DEBIAN_FRONTEND=noninteractive silently
    # keeps whatever display manager (e.g. gdm3) was already the default instead
    # of prompting to switch - so set it explicitly if sddm just got installed.
    if dpkg -l sddm 2>/dev/null | grep -q '^ii'; then
        log "Setting sddm as the default display manager..."
        echo "sddm shared/default-x-display-manager select sddm" | sudo debconf-set-selections
        sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure sddm
        # dpkg-reconfigure only updates /etc/X11/default-display-manager; --force
        # repoints the display-manager.service alias away from gdm3 to sddm.
        sudo systemctl enable sddm --force
        local dm; dm="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
        if [[ "$dm" != */sddm ]]; then
            # Non-interactive switch didn't take: fall back to the interactive
            # prompt (pick sddm there), then re-point the service again.
            warn "Default display manager is '$dm', not sddm - running 'dpkg-reconfigure sddm' interactively; choose sddm."
            sudo dpkg-reconfigure sddm
            sudo systemctl enable sddm --force
            dm="$(cat /etc/X11/default-display-manager 2>/dev/null || true)"
        fi
        if [[ "$dm" == */sddm ]]; then
            log "Default display manager: $dm"
        else
            warn "Default display manager is still '$dm', not sddm."
        fi
    fi
}
