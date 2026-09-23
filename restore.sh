#!/usr/bin/env bash
# Applies this repo's backup to the current machine.
# Usage: ./restore.sh [--only=step1,step2] [--skip=step1,step2]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

ONLY=""
SKIP=""

for arg in "$@"; do
    case "$arg" in
        --only=*) ONLY="${arg#--only=}" ;;
        --skip=*) SKIP="${arg#--skip=}" ;;
        *) err "unknown argument: $arg"; exit 1 ;;
    esac
done

# Ordered list of steps. Each step "$s" must define restore_$s in modules/$s.sh.
STEPS=(packages_remove packages_apt packages_snap packages_flatpak installers vscode_extensions dotfiles tools_scripts tools_installers conda_envs winapps ssh_gpg)

should_run() {
    local step="$1"
    if [[ -n "$ONLY" ]]; then
        [[ ",$ONLY," == *",$step,"* ]]
    elif [[ -n "$SKIP" ]]; then
        [[ ",$SKIP," != *",$step,"* ]]
    else
        return 0
    fi
}

for step in "${STEPS[@]}"; do
    if should_run "$step"; then
        log "== $step =="
        source "$SCRIPT_DIR/modules/${step}.sh"
        "restore_${step}"
    fi
done

log "Done."
warn "Reboot (or at least restart the display manager) to switch into the KDE/Plasma session."
