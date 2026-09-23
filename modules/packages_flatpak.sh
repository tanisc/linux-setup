#!/usr/bin/env bash
# flatpak: manifest-driven package install (restore-only), from the flathub remote.

restore_packages_flatpak() {
    local manifest="$SCRIPT_DIR/manifests/packages-flatpak.list"
    if ! command -v flatpak >/dev/null 2>&1; then
        warn "flatpak not installed, skipping flatpak packages."
        return
    fi

    if [[ ! -s "$manifest" ]]; then
        warn "manifests/packages-flatpak.list not found or empty, skipping."
        return
    fi

    if ! flatpak remote-list | grep -q '^flathub'; then
        log "Adding flathub remote..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi

    mapfile -t apps < <(grep -vE '^\s*(#|$)' "$manifest")
    for app in "${apps[@]}"; do
        log "Installing flatpak: $app"
        flatpak install -y flathub "$app"
    done
}
