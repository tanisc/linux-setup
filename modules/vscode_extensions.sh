#!/usr/bin/env bash
# VS Code extensions, driven by manifests/vscode-extensions.list (restore-only,
# hand-curated - same pattern as the package manifests).

restore_vscode_extensions() {
    local manifest="$SCRIPT_DIR/manifests/vscode-extensions.list"
    if ! command -v code >/dev/null 2>&1; then
        warn "code (VS Code) not found on PATH, skipping extensions."
        return
    fi
    if [[ ! -s "$manifest" ]]; then
        warn "manifests/vscode-extensions.list not found or empty, skipping."
        return
    fi

    local ext
    while IFS= read -r ext; do
        log "Installing VS Code extension: $ext"
        code --install-extension "$ext"
    done < <(grep -vE '^\s*(#|$)' "$manifest")
}
