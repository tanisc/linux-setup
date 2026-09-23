#!/usr/bin/env bash
# Shared helpers sourced by restore.sh/backup.sh and modules.

log()  { printf '\033[1;34m[*]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; }

require_sudo() {
    if ! sudo -v; then
        err "sudo access is required for this step"
        exit 1
    fi
}

# Strips a leading "~/" from a manifest entry, giving a path relative to $HOME.
strip_home_prefix() {
    local p="$1"
    printf '%s' "${p#\~/}"
}

# Reads a manifest file, printing one relative-to-$HOME path per line.
# Skips blank lines and lines starting with #.
read_manifest() {
    local manifest="$1"
    [[ -s "$manifest" ]] || return 0
    local line
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        strip_home_prefix "$line"
    done < "$manifest"
}

# Copies $HOME/<rel> into <repo>/data/<rel>, mirroring the path exactly.
backup_path() {
    local rel="$1"
    local src="$HOME/$rel"
    local dest="$SCRIPT_DIR/data/$rel"
    if [[ ! -e "$src" ]]; then
        warn "backup: $src not found, skipping"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    cp -a "$src" "$dest"
    log "Backed up ~/$rel"
}

# Copies <repo>/data/<rel> into $HOME/<rel>, replacing whatever is there.
restore_path() {
    local rel="$1"
    local src="$SCRIPT_DIR/data/$rel"
    local dest="$HOME/$rel"
    if [[ ! -e "$src" ]]; then
        warn "restore: no backup found for ~/$rel, skipping"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    rm -rf "$dest"
    cp -a "$src" "$dest"
    log "Restored ~/$rel"
}
