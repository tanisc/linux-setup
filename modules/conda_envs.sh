#!/usr/bin/env bash
# Conda environments, exported as data/.env/<name>.yml (`conda env export`) and
# recreated from those files on restore. Restore must run after
# tools_installers, which installs Miniconda into ~/.miniconda.

CONDA_ENVS_DIR="$SCRIPT_DIR/data/.env"

# Prints the conda executable: ~/.miniconda first, then whatever is on PATH.
find_conda() {
    if [[ -x "$HOME/.miniconda/bin/conda" ]]; then
        printf '%s\n' "$HOME/.miniconda/bin/conda"
    else
        command -v conda || true
    fi
}

backup_conda_envs() {
    local conda; conda="$(find_conda)"
    if [[ -z "$conda" ]]; then
        warn "conda not found, skipping."
        return
    fi
    local root; root="$("$conda" info --base)"

    mkdir -p "$CONDA_ENVS_DIR"

    local prefix name
    while IFS= read -r prefix; do
        if [[ "$prefix" == "$root" ]]; then
            name="base"
        else
            name="$(basename "$prefix")"
        fi
        "$conda" env export -p "$prefix" > "$CONDA_ENVS_DIR/$name.yml"
        log "Exported conda env '$name' -> data/.env/$name.yml"
    done < <("$conda" env list | awk '!/^#/ && NF {print $NF}')
}

restore_conda_envs() {
    local conda; conda="$(find_conda)"
    if [[ -z "$conda" ]]; then
        warn "conda not found (is miniconda in tools-installers.list?), skipping."
        return
    fi
    if ! compgen -G "$CONDA_ENVS_DIR/*.yml" >/dev/null; then
        warn "No data/.env/*.yml found, skipping."
        return
    fi

    # Accept Anaconda's channel ToS up front so env creation doesn't stop at
    # an interactive (a)ccept/(r)eject prompt.
    if "$conda" tos --help >/dev/null 2>&1; then
        local channel
        for channel in https://repo.anaconda.com/pkgs/main https://repo.anaconda.com/pkgs/r; do
            log "Accepting conda ToS for $channel"
            "$conda" tos accept --override-channels --channel "$channel"
        done
    fi

    local file name
    for file in "$CONDA_ENVS_DIR"/*.yml; do
        name="$(basename "$file" .yml)"
        if [[ "$name" == "base" ]]; then
            # base can't be removed/recreated, only updated in place.
            log "Updating conda base env from $name.yml"
            "$conda" env update -n base -f "$file"
        else
            if "$conda" env list | awk '{print $1}' | grep -qx "$name"; then
                "$conda" env remove -n "$name" -y
            fi
            log "Creating conda env '$name' from $name.yml"
            "$conda" env create -n "$name" -f "$file"
        fi
    done
}
