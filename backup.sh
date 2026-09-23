#!/usr/bin/env bash
# Captures this machine's state into this repo's data/ folder.
# Usage: ./backup.sh [--only=step1,step2] [--skip=step1,step2]

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

# Ordered list of steps. Each step "$s" must define backup_$s in modules/$s.sh.
STEPS=(dotfiles tools_scripts ssh_gpg winapps conda_envs)

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
        "backup_${step}"
    fi
done

log "Done."
