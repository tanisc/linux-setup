#!/usr/bin/env bash
# Generic config files/dirs, driven by manifests/dotfiles.list.

backup_dotfiles() {
    local rel
    while IFS= read -r rel; do
        backup_path "$rel"
    done < <(read_manifest "$SCRIPT_DIR/manifests/dotfiles.list")
}

restore_dotfiles() {
    local rel
    while IFS= read -r rel; do
        restore_path "$rel"
    done < <(read_manifest "$SCRIPT_DIR/manifests/dotfiles.list")
}
