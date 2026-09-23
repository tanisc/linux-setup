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
}
