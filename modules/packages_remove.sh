#!/usr/bin/env bash
# Removes unwanted default apps (e.g. firefox) via manifest, both apt and snap.

restore_packages_remove() {
    local apt_manifest="$SCRIPT_DIR/manifests/packages-apt-remove.list"
    local snap_manifest="$SCRIPT_DIR/manifests/packages-snap-remove.list"

    if [[ -s "$apt_manifest" ]]; then
        mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$apt_manifest")
        if [[ ${#pkgs[@]} -gt 0 ]]; then
            require_sudo
            log "Purging apt package(s): ${pkgs[*]}"
            sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y "${pkgs[@]}" || true
            sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y || true

            # Pin them to never be (re)installed, since some (e.g. firefox) come back
            # as a Recommends of a later package (e.g. kubuntu-desktop) otherwise.
            log "Pinning removed package(s) to prevent reinstallation via Recommends..."
            {
                for pkg in "${pkgs[@]}"; do
                    printf 'Package: %s\nPin: release *\nPin-Priority: -1\n\n' "$pkg"
                done
            } | sudo tee /etc/apt/preferences.d/linux-setup-no-reinstall.pref > /dev/null
        fi
    fi

    if [[ -s "$snap_manifest" ]] && command -v snap >/dev/null 2>&1; then
        mapfile -t snaps < <(grep -vE '^\s*(#|$)' "$snap_manifest")
        for name in "${snaps[@]}"; do
            if snap list "$name" >/dev/null 2>&1; then
                require_sudo
                log "Removing snap: $name"
                sudo snap remove "$name"
            fi
        done
    fi
}
