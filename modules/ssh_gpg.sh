#!/usr/bin/env bash
# ~/.ssh and ~/.gnupg, with permissions fixed up explicitly since a fresh
# account/umask can't be trusted to produce ssh/gpg-acceptable modes.

backup_ssh_gpg() {
    backup_path ".ssh"
    backup_path ".gnupg"
}

restore_ssh_gpg() {
    restore_path ".ssh"
    restore_path ".gnupg"

    if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        find "$HOME/.ssh" -type f -name '*.pub' -exec chmod 644 {} +
        find "$HOME/.ssh" -type f ! -name '*.pub' -exec chmod 600 {} +
        log "Fixed ~/.ssh permissions (700 dir, 600 keys, 644 *.pub)"
    fi

    if [[ -d "$HOME/.gnupg" ]]; then
        find "$HOME/.gnupg" -type d -exec chmod 700 {} +
        find "$HOME/.gnupg" -type f -exec chmod 600 {} +
        log "Fixed ~/.gnupg permissions (700 dirs, 600 files)"
    fi
}
