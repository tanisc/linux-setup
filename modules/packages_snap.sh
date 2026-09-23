#!/usr/bin/env bash
# snap: manifest-driven package install (restore-only).

restore_packages_snap() {
    local manifest="$SCRIPT_DIR/manifests/packages-snap.list"
    if ! command -v snap >/dev/null 2>&1; then
        warn "snap not installed, skipping snap packages."
        return
    fi

    if [[ ! -s "$manifest" ]]; then
        warn "manifests/packages-snap.list not found or empty, skipping."
        return
    fi

    require_sudo

    local line name mode
    while IFS= read -r line; do
        [[ "$line" =~ ^\s*(#|$) ]] && continue
        name="$(awk '{print $1}' <<<"$line")"
        mode="$(awk '{print $2}' <<<"$line")"
        log "Installing snap: $name${mode:+ ($mode)}"
        if [[ "$mode" == "classic" ]]; then
            sudo snap install "$name" --classic
        else
            sudo snap install "$name"
        fi
    done < "$manifest"
}
