#!/usr/bin/env bash
# Plain scripts under ~/.tools, driven by manifests/tools-scripts.list.
# (Installer-based apps under ~/.tools are handled separately, see tools-installers.list.)

backup_tools_scripts() {
    local rel
    while IFS= read -r rel; do
        backup_path "$rel"
    done < <(read_manifest "$SCRIPT_DIR/manifests/tools-scripts.list")
}

restore_tools_scripts() {
    local rel
    while IFS= read -r rel; do
        restore_path "$rel"
        # Scripts should stay executable even if the source lost the bit somehow.
        local dest="$HOME/$rel"
        [[ -f "$dest" ]] && chmod +x "$dest"
    done < <(read_manifest "$SCRIPT_DIR/manifests/tools-scripts.list")
}
