#!/usr/bin/env bash
# Installer-based apps that live under ~/.tools (can't just be copied),
# driven by manifests/tools-installers.list ("<name> <install_dir>" per line).
# name (hyphens -> underscores) must map to install_<name>() below.

install_esa_snap() {
    local dir="$1"
    local installer="/tmp/esa-snap_sentinel_linux-14.0.0.sh"
    log "Downloading ESA SNAP installer (~1.1GB, this will take a while)..."
    curl -fL -o "$installer" "https://download.esa.int/step/snap/14.0/installers/esa-snap_sentinel_linux-14.0.0.sh"
    chmod +x "$installer"
    mkdir -p "$dir"
    log "Running SNAP installer unattended into $dir ..."
    # -q/-dir are install4j's documented silent-install switches (confirmed this
    # is an install4j installer from its embedded INSTALL4J_* env vars), but this
    # exact invocation was never actually run/verified end-to-end - check the
    # result after the first real restore.
    "$installer" -q -dir "$dir"
    rm -f "$installer"
}

install_panoply() {
    local dir="$1"
    local tgz="/tmp/PanoplyJ-5.10.1.tgz"
    log "Downloading Panoply..."
    curl -fL -o "$tgz" "https://www.giss.nasa.gov/tools/panoply/download/PanoplyJ-5.10.1.tgz"
    local tmpdir; tmpdir="$(mktemp -d)"
    tar xzf "$tgz" -C "$tmpdir"
    mkdir -p "$(dirname "$dir")"
    rm -rf "$dir"
    mv "$tmpdir/PanoplyJ" "$dir"
    chmod +x "$dir/panoply.sh"
    rm -rf "$tmpdir" "$tgz"
    log "Panoply extracted to $dir (run with $dir/panoply.sh)"
}

install_miniconda() {
    local dir="$1"
    local installer="/tmp/Miniconda3-latest-Linux-x86_64.sh"
    log "Downloading Miniconda installer..."
    curl -fL -o "$installer" "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    mkdir -p "$(dirname "$dir")"
    log "Running Miniconda installer unattended into $dir ..."
    # -b: batch mode (no prompts, accepts the license), -u: update instead of
    # failing if $dir already exists, -p: install prefix, -c: run `conda init`
    # (appends the conda block to ~/.bashrc; only applies in batch mode).
    bash "$installer" -b -u -c -p "$dir"
    rm -f "$installer"
}

restore_tools_installers() {
    local manifest="$SCRIPT_DIR/manifests/tools-installers.list"
    if [[ ! -s "$manifest" ]]; then
        warn "manifests/tools-installers.list not found or empty, skipping."
        return
    fi
    local line name dir fn
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        name="$(awk '{print $1}' <<<"$line")"
        dir="$(awk '{print $2}' <<<"$line")"
        dir="${dir/#\~/$HOME}"
        fn="install_${name//-/_}"
        if declare -f "$fn" >/dev/null; then
            log "Installing (tools): $name -> $dir"
            "$fn" "$dir"
        else
            warn "No $fn() defined in modules/tools_installers.sh, skipping '$name'"
        fi
    done < "$manifest"
}
