#!/usr/bin/env bash
# System-wide installer apps, driven by manifests/installers.list.
# Each manifest entry "$name" must have a matching install_$name() below.

install_chrome() {
    local deb="/tmp/google-chrome-stable_current_amd64.deb"
    log "Downloading Chrome..."
    curl -fL -o "$deb" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    require_sudo
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb"
    rm -f "$deb"
}

install_vscode() {
    if ! command -v code >/dev/null 2>&1; then
        require_sudo
        log "Adding Microsoft VS Code apt repo..."
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        rm -f /tmp/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
            | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    fi
    require_sudo
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y code
}

install_claude() {
    local tmpdir; tmpdir="$(mktemp -d)"
    (
        cd "$tmpdir"
        local arch pkgfile
        arch="$(dpkg --print-architecture)"
        pkgfile="$(curl -s "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-${arch}/Packages" \
            | grep '^Filename: pool/main/c/claude-desktop/claude-desktop_' | sort -V | tail -n 1 | cut -d' ' -f2)"
        log "Downloading Claude desktop ($pkgfile)..."
        curl -fLO "https://downloads.claude.ai/claude-desktop/apt/stable/${pkgfile}"
        require_sudo
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./claude-desktop_*.deb
    )
    rm -rf "$tmpdir"
}

install_docker() {
    require_sudo

    local conflicting=(docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc)
    local installed
    installed="$(dpkg --get-selections "${conflicting[@]}" 2>/dev/null | awk '{print $1}')" || true
    if [[ -n "$installed" ]]; then
        log "Removing conflicting docker packages: $installed"
        # shellcheck disable=SC2086
        sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y $installed
    fi

    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl

    log "Adding Docker's official apt repo..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    ( . /etc/os-release
      sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    )

    sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log "Adding $USER to the docker group (log out/in for it to take effect)..."
    sudo usermod -aG docker "$USER"

    log "Verifying docker install..."
    sudo docker run hello-world || warn "docker hello-world check failed, verify manually"
}

restore_installers() {
    local manifest="$SCRIPT_DIR/manifests/installers.list"
    if [[ ! -s "$manifest" ]]; then
        warn "manifests/installers.list not found or empty, skipping."
        return
    fi
    local name fn
    while IFS= read -r name; do
        fn="install_${name}"
        if declare -f "$fn" >/dev/null; then
            log "Installing: $name"
            "$fn"
        else
            warn "No $fn() defined in modules/installers.sh, skipping '$name'"
        fi
    done < <(grep -vE '^\s*(#|$)' "$manifest")
}
