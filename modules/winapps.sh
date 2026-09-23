#!/usr/bin/env bash
# WinApps (https://github.com/winapps-org/winapps): runs Windows in Docker,
# then links Windows apps into Linux.
#
# The whole ~/.tools/winapps repo (including your customized compose.yaml) is
# backed up and restored as-is, NOT re-cloned from GitHub - this pins it to
# whatever version was working when you backed up, avoiding a mismatch between
# a freshly-cloned compose.yaml and your saved config.
#
# Depends on: `docker` (installers step) and ~/.config/winapps/winapps.conf
# (dotfiles step) already being in place.
#
# This step is NOT unattended - it pauses for you to finish the Windows setup
# in a browser, and the final wizard is an interactive dialog UI by design.

WINAPPS_DIR_REL=".tools/winapps"

backup_winapps() {
    backup_path "$WINAPPS_DIR_REL"
}

restore_winapps() {
    local dir="$HOME/$WINAPPS_DIR_REL"

    restore_path "$WINAPPS_DIR_REL"

    if [[ ! -f "$dir/compose.yaml" ]]; then
        warn "No backed-up winapps repo found at $dir, skipping."
        return
    fi

    log "Starting the Windows VM container (downloads a Windows image, can take a long time)..."
    # sg picks up the docker group install_docker() just granted, without needing a fresh login.
    sg docker -c "cd '$dir' && docker compose --file ./compose.yaml up -d"

    warn "Open http://127.0.0.1:8006 in your browser to finish the Windows installation, then install any apps you need from the Microsoft Store (e.g. Office) and set your keyboard input language."
    local ans=""
    while [[ "$ans" != "COMPLETE" ]]; do
        read -r -p "Type COMPLETE once Windows setup is finished: " ans
    done

    log "Launching the WinApps setup wizard - this is where you select which Windows apps get linked into Linux. Follow the on-screen prompts."
    sg docker -c "cd '$dir' && bash ./setup.sh"
}
