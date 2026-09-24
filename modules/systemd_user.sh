#!/usr/bin/env bash
# systemd user units (~/.config/systemd/user/<unit>), driven by
# manifests/systemd-user-units.list. Restore copies them back, then enables and
# starts each one. Runs after dotfiles, since units like rclone-onedrive.service
# need the restored ~/.config/rclone/rclone.conf.

SYSTEMD_USER_DIR=".config/systemd/user"

backup_systemd_user() {
    local unit
    while IFS= read -r unit; do
        backup_path "$SYSTEMD_USER_DIR/$unit"
    done < <(read_manifest "$SCRIPT_DIR/manifests/systemd-user-units.list")
}

restore_systemd_user() {
    local units=() unit
    while IFS= read -r unit; do
        restore_path "$SYSTEMD_USER_DIR/$unit"
        [[ -f "$HOME/$SYSTEMD_USER_DIR/$unit" ]] && units+=("$unit")
    done < <(read_manifest "$SCRIPT_DIR/manifests/systemd-user-units.list")

    (( ${#units[@]} )) || return 0

    # Create each unit's mount point up front (~/OneDrive, ~/GoogleDrive, ...):
    # the dirs named by its "ExecStartPre=/usr/bin/mkdir -p %h/<dir>" line(s).
    # The units create them too on start; this just doesn't depend on that.
    local dir
    for unit in "${units[@]}"; do
        while IFS= read -r dir; do
            mkdir -p "$HOME/$dir"
            log "Created ~/$dir"
        done < <(sed -n 's|^ExecStartPre=.*mkdir -p %h/\([^[:space:]]*\).*|\1|p' "$HOME/$SYSTEMD_USER_DIR/$unit")
    done

    systemctl --user daemon-reload

    # A unit that fails to start (e.g. no network, missing rclone remote) only
    # warns, so the rest of the restore still runs.
    for unit in "${units[@]}"; do
        if systemctl --user enable --now "$unit"; then
            log "Enabled and started $unit ($(systemctl --user is-active "$unit" || true))"
        else
            warn "Failed to enable/start $unit - check: systemctl --user status $unit"
        fi
    done
}
