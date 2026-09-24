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

    # conda prints a CondaExportWarning listing every pip-installed package to
    # stderr; capture stderr and replace that block with a one-line summary.
    local errfile; errfile="$(mktemp)"
    local prefix name npip other
    while IFS= read -r prefix; do
        if [[ "$prefix" == "$root" ]]; then
            name="base"
        else
            name="$(basename "$prefix")"
        fi
        if ! "$conda" env export -p "$prefix" > "$CONDA_ENVS_DIR/$name.yml" 2> "$errfile"; then
            cat "$errfile" >&2
            rm -f "$errfile"
            err "Exporting conda env '$name' failed"
            return 1
        fi
        log "Exported conda env '$name' -> data/.env/$name.yml"

        npip="$(grep -oE 'contains [0-9]+ packages? installed via pip' "$errfile" | grep -oE '[0-9]+' || true)"
        [[ -n "$npip" ]] && warn "  $name: $npip pip package(s) (in the .yml, but conda can't pin them exactly)"
        # Anything else on stderr (outside the warning block) is still shown.
        other="$(awk '/CondaExportWarning: /{skip=1} !skip && NF; /warnings\.warn\(warning, CondaExportWarning\)/{skip=0}' "$errfile")"
        [[ -n "$other" ]] && printf '%s\n' "$other" >&2
    done < <("$conda" env list | awk '!/^#/ && NF {print $NF}')
    rm -f "$errfile"
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

    # A failing env (e.g. a pip package that won't build) only warns, so the
    # remaining envs and later restore steps (winapps, ssh_gpg) still run.
    local file name failed=()
    for file in "$CONDA_ENVS_DIR"/*.yml; do
        name="$(basename "$file" .yml)"
        if [[ "$name" == "base" ]]; then
            # base can't be removed/recreated, only updated in place.
            log "Updating conda base env from $name.yml"
            "$conda" env update -n base -f "$file" || failed+=("$name")
        else
            if "$conda" env list | awk '{print $1}' | grep -qx "$name"; then
                "$conda" env remove -n "$name" -y || { failed+=("$name"); continue; }
            fi
            log "Creating conda env '$name' from $name.yml"
            "$conda" env create -n "$name" -f "$file" || failed+=("$name")
        fi
    done

    if (( ${#failed[@]} )); then
        warn "Failed to restore conda env(s): ${failed[*]} - see output above, fix and retry with:"
        warn "  conda env remove -n <name> -y && conda env create -f data/.env/<name>.yml"
    fi
}
