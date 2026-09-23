#!/usr/bin/env bash
# ~/.ssh (and later ~/.gnupg), with permissions fixed up explicitly since a
# fresh account/umask can't be trusted to produce ssh-acceptable modes.

backup_ssh_gpg() {
    backup_path ".ssh"
}

restore_ssh_gpg() {
    restore_path ".ssh"

    if [[ -d "$HOME/.ssh" ]]; then
        chmod 700 "$HOME/.ssh"
        find "$HOME/.ssh" -type f -name '*.pub' -exec chmod 644 {} +
        find "$HOME/.ssh" -type f ! -name '*.pub' -exec chmod 600 {} +
        log "Fixed ~/.ssh permissions (700 dir, 600 keys, 644 *.pub)"
    fi
}
