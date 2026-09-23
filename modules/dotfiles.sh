#!/usr/bin/env bash
# Generic config files/dirs, driven by manifests/dotfiles.list.

# Dotfiles holding credentials; forced to 600 after restore regardless of the
# mode they were backed up with (paths relative to $HOME).
SECRET_DOTFILES=(
    .config/rclone/rclone.conf    # S3/SFTP keys and passwords
    .s3cfg                        # s3cmd S3 keys
    .config/winapps/winapps.conf  # WinApps RDP password
)

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

    local f
    for f in "${SECRET_DOTFILES[@]}"; do
        if [[ -f "$HOME/$f" ]]; then
            chmod 600 "$HOME/$f"
            log "Set ~/$f to 600"
        fi
    done
}
