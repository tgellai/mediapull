# ============================================================
# mediapull — Bash autocomplete
# Loaded automatically via ~/.bashrc
# ============================================================

_mediapull_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    # Find project input/ dir relative to script location
    local script_path
    script_path=$(which mediapull.sh 2>/dev/null)
    [[ -z "$script_path" ]] && return

    local input_dir
    input_dir="$(dirname "$(dirname "$script_path")")/input"
    [[ ! -d "$input_dir" ]] && return

    # First argument: autocomplete input files
    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        local files
        files=$(ls "$input_dir" 2>/dev/null)
        COMPREPLY=($(compgen -W "$files" -- "$cur"))
        return
    fi

    # Subsequent arguments: yt-dlp flags (dynamic from help, cached) +
    # extra flags not listed in --help
    local cache_file="$HOME/.mediapull_flags_cache"
    local extra_flags="--no-extract-audio --yes-playlist --no-yes-playlist"

    local ytdlp_flags
    ytdlp_flags=$(cat "$cache_file" 2>/dev/null || \
        yt-dlp --help | grep -oP '^\s+\-\-[a-z][a-z0-9-]+' | tr -d ' ' | tr '\n' ' ' | \
        tee "$cache_file")

    COMPREPLY=($(compgen -W "$ytdlp_flags $extra_flags" -- "$cur"))
}

complete -F _mediapull_completion mediapull.sh
complete -F _mediapull_completion mediapull
