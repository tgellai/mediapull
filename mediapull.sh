#!/bin/bash

# ============================================================
# mediapull — Batch media downloader built on yt-dlp
# https://github.com/[yourusername]/mediapull
#
# Project structure:
#   ~/mediapull/
#   ├── bin/mediapull.sh          (this script)
#   ├── bin/mediapull_completion.sh
#   ├── config/config.yaml        (default yt-dlp settings)
#   ├── input/                    (put your URL list files here)
#   └── output/                   (downloaded files land here)
#
# Usage:
#   mediapull.sh <input_file> [yt-dlp options...]
#
# Examples:
#   mediapull.sh my_videos.md
#   mediapull.sh my_videos.md --audio-format wav
#   mediapull.sh my_videos.md --sleep-interval 3 --audio-quality 0
# ============================================================

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INPUT_DIR="$PROJECT_DIR/input"
OUTPUT_BASE="$PROJECT_DIR/output"
CONFIG_FILE="$PROJECT_DIR/config/config.yaml"

# --- Globals ---
FAILED_URLS=()
SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
OUTPUT_DIR=""
LOG_FILE=""

# --- Dependency check ---
check_dependencies() {
    local missing=()
    for cmd in yt-dlp ffmpeg yq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "ERROR: Missing dependencies: ${missing[*]}"
        echo "Install with: sudo apt install ffmpeg && pip3 install yt-dlp && sudo snap install yq"
        exit 1
    fi
}

# --- Log function ---
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# --- Build yt-dlp args from config.yaml ---
build_config_args() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo ""
        return
    fi

    local args=""

    # Audio extraction
    local extract_audio
    extract_audio=$(yq '.extract_audio // "true"' "$CONFIG_FILE")
    [[ "$extract_audio" == "true" ]] && args+=" -x"

    # Audio format
    local audio_format
    audio_format=$(yq '.audio_format // ""' "$CONFIG_FILE")
    [[ -n "$audio_format" && "$audio_format" != "null" ]] && args+=" --audio-format $audio_format"

    # Audio quality
    local audio_quality
    audio_quality=$(yq '.audio_quality // ""' "$CONFIG_FILE")
    [[ -n "$audio_quality" && "$audio_quality" != "null" ]] && args+=" --audio-quality $audio_quality"

    # Sleep interval
    local sleep_interval
    sleep_interval=$(yq '.sleep_interval // ""' "$CONFIG_FILE")
    [[ -n "$sleep_interval" && "$sleep_interval" != "null" ]] && args+=" --sleep-interval $sleep_interval"

    # Retries
    local retries
    retries=$(yq '.retries // ""' "$CONFIG_FILE")
    [[ -n "$retries" && "$retries" != "null" ]] && args+=" --retries $retries"

    # Extra raw flags (list of strings)
    local extra_flags
    extra_flags=$(yq '.extra_flags[]? // ""' "$CONFIG_FILE" 2>/dev/null)
    while IFS= read -r flag; do
        [[ -n "$flag" && "$flag" != "null" ]] && args+=" $flag"
    done <<< "$extra_flags"

    echo "$args"
}

# --- Download function ---
download_media() {
    local url="$1"
    local index="$2"
    local config_args="$3"
    local extra_args="$4"

    local output_name
    output_name=$(printf "video_%03d" "$index")
    local output_path="$OUTPUT_DIR/$output_name.%(ext)s"

    # Check if already downloaded (any extension)
    local index_padded
    index_padded=$(printf "%03d" "$index")
    if ls "$OUTPUT_DIR/video_${index_padded}."* &>/dev/null 2>&1; then
        log "SKIP" "video_${index_padded} already exists, skipping: $url"
        ((SKIP_COUNT++))
        return 0
    fi

    log "START" "[$index] Downloading: $url"

    # shellcheck disable=SC2086
    if yt-dlp $config_args $extra_args "$url" -o "$output_path" >> "$LOG_FILE" 2>&1; then
        log "OK" "[$index] Success"
        ((SUCCESS_COUNT++))
    else
        log "FAIL" "[$index] Failed: $url"
        FAILED_URLS+=("$url")
        ((FAIL_COUNT++))
    fi
}

# --- Main ---
main() {
    check_dependencies

    if [[ -z "$1" ]]; then
        echo "mediapull — Batch media downloader"
        echo ""
        echo "Usage: mediapull.sh <input_file> [yt-dlp options...]"
        echo ""
        echo "Available input files:"
        ls "$INPUT_DIR" 2>/dev/null || echo "  (input/ directory is empty)"
        exit 1
    fi

    local input_filename="$1"
    local input_file="$INPUT_DIR/$input_filename"
    shift  # Remove first arg — rest are passed to yt-dlp
    local extra_args="$*"

    if [[ ! -f "$input_file" ]]; then
        echo "File not found: $input_file"
        echo "Available files in input/:"
        ls "$INPUT_DIR" 2>/dev/null || echo "  (empty)"
        exit 1
    fi

    # Setup output dir (named after input file, without extension)
    local dir_name="${input_filename%.*}"
    OUTPUT_DIR="$OUTPUT_BASE/$dir_name"
    LOG_FILE="$OUTPUT_DIR/mediapull_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$OUTPUT_DIR"

    # Build args from config
    local config_args
    config_args=$(build_config_args)

    log "INFO" "mediapull started"
    log "INFO" "Input file:    $input_file"
    log "INFO" "Output dir:    $OUTPUT_DIR"
    log "INFO" "Config args:   $config_args"
    log "INFO" "Override args: $extra_args"
    log "INFO" "================================"

    local index=1
    while IFS= read -r url || [[ -n "$url" ]]; do
        [[ -z "$url" || "$url" == \#* ]] && continue
        download_media "$url" "$index" "$config_args" "$extra_args"
        ((index++))
    done < "$input_file"

    log "INFO" "================================"
    log "INFO" "SUMMARY:"
    log "INFO" "  Success:  $SUCCESS_COUNT"
    log "INFO" "  Skipped:  $SKIP_COUNT"
    log "INFO" "  Failed:   $FAIL_COUNT"

    if [[ ${#FAILED_URLS[@]} -gt 0 ]]; then
        log "WARN" "Failed URLs:"
        for u in "${FAILED_URLS[@]}"; do
            log "WARN" "  - $u"
        done
    fi

    log "INFO" "Done. Files saved to: $OUTPUT_DIR"
}

main "$@"
