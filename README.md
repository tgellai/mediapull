<div align="center">

```
                    _ _                      _ _ 
  _ __ ___   ___  __| (_) __ _ _ __  _   _| | |
 | '_ ` _ \ / _ \/ _` | |/ _` | '_ \| | | | | |
 | | | | | |  __/ (_| | | (_| | |_) | |_| | | |
 |_| |_| |_|\___|\__,_|_|\__,_| .__/ \__,_|_|_|
                                |_|              
```

**Batch media downloader built on yt-dlp**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20%7C%20WSL-blue.svg)](https://github.com/microsoft/WSL)
[![Powered by yt-dlp](https://img.shields.io/badge/Powered%20by-yt--dlp-red.svg)](https://github.com/yt-dlp/yt-dlp)
[![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

*Download entire URL lists in one command. Config-driven. Log-everything. Skip what's done.*

</div>

---

## What is this?

`mediapull` wraps [yt-dlp](https://github.com/yt-dlp/yt-dlp) to batch-download media from a plain text URL list. Instead of running yt-dlp manually for each video, you drop your links into a file and let mediapull handle the rest — with structured output, logging, skip logic, and full yt-dlp pass-through.

Works with **Vimeo, YouTube, and [1000+ other sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)** that yt-dlp supports.

---

## Features

- **Batch download** from a plain `.md` or `.txt` URL list — one URL per line
- **YAML config** for default yt-dlp settings — set once, reuse everywhere
- **Pass-through flags** — override any yt-dlp option at runtime without touching config
- **Structured output** — each input file gets its own named output directory
- **Skip logic** — already downloaded files are skipped on re-run (safe to interrupt)
- **Timestamped logs** — every run creates a detailed log next to the output files
- **Bash autocomplete** — TAB to select input files and yt-dlp flags
- **Dependency check** — fails fast with a clear message if yt-dlp/ffmpeg/yq are missing

---

## Project structure

```
~/mediapull/
├── bin/
│   ├── mediapull              # symlink → mediapull.sh
│   ├── mediapull.sh           # main script
│   └── mediapull_completion.sh
├── config/
│   └── config.yaml            # your default settings
├── input/
│   └── my_videos.md           # URL list files go here
└── output/
    └── my_videos/             # auto-created per input file
        ├── video_001.mp3
        ├── video_002.mp3
        └── mediapull_20250218_143022.log
```

---

## Installation

**Dependencies:** `yt-dlp`, `ffmpeg`, `yq`

```bash
# Clone the repo
git clone https://github.com/tgellai/mediapull.git
cd mediapull

# Run setup — installs dependencies, sets PATH, enables autocomplete
bash setup.sh
```

Open a new terminal after setup. Done.

---

## Usage

```bash
# Basic — uses config.yaml defaults
mediapull my_videos.md

# Override audio format for this run
mediapull my_videos.md --audio-format wav

# Download video instead of audio
mediapull my_videos.md    # set extract_audio: false in config.yaml

# Slow down between downloads (avoid rate limiting)
mediapull my_videos.md --sleep-interval 5

# Any yt-dlp flag works
mediapull my_videos.md --audio-quality 0 --embed-thumbnail --retries 5
```

TAB autocomplete works for both input files and yt-dlp flags:

```bash
mediapull [TAB]              # lists files in input/
mediapull my_videos.md --[TAB][TAB]   # lists all yt-dlp flags
```

---

## Input file format

Plain text, one URL per line. Comments (`#`) and blank lines are ignored.

```
# Module 1
https://player.vimeo.com/video/XXXXXXXXX
https://player.vimeo.com/video/XXXXXXXXX

# Module 2
https://player.vimeo.com/video/XXXXXXXXX
https://player.vimeo.com/video/XXXXXXXXX
```

---

## Configuration

Edit `config/config.yaml` to set your defaults:

```yaml
# Extract audio only — set to false to keep video
extract_audio: true

# Audio format: mp3 | wav | m4a | flac | opus | vorbis | aac
audio_format: mp3

# Audio quality: 0 (best VBR) → 10 (worst) | or fixed bitrate e.g. 128K
audio_quality: 0

# Seconds to wait between downloads — be polite to servers
sleep_interval: 1

# Retry count on network failure
retries: 3

# Optional: any extra yt-dlp flags
# extra_flags:
#   - "--embed-thumbnail"
#   - "--embed-metadata"
#   - "--no-playlist"
```

### Config + override priority

Command-line flags **extend** the config, they don't replace it:

```bash
# config.yaml:  audio_format: mp3
# command line: --audio-format wav
# result:       --audio-format wav wins (yt-dlp uses last value)
```

### Resetting the flag cache

mediapull caches yt-dlp's available flags for faster TAB completion. If you update yt-dlp and want fresh flags:

```bash
rm ~/.mediapull_flags_cache
```

---

## Output

Each run creates a directory named after the input file:

```
output/
└── my_videos/
    ├── video_001.mp3
    ├── video_002.mp3
    ├── video_003.mp3
    └── mediapull_20250218_143022.log
```

The log contains full yt-dlp output for every download, plus a summary:

```
[2025-02-18 14:30:22] [INFO] mediapull started
[2025-02-18 14:30:22] [INFO] Config args:    -x --audio-format mp3 --audio-quality 0
[2025-02-18 14:31:05] [OK]   [1] Success
[2025-02-18 14:31:05] [SKIP] video_002 already exists, skipping
[2025-02-18 14:32:11] [FAIL] [3] Failed: https://...
[2025-02-18 14:32:11] [INFO] SUMMARY: Success: 1 | Skipped: 1 | Failed: 1
```

---

## Requirements

| Tool | Version | Install |
|------|---------|---------|
| `yt-dlp` | latest | `curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp` |
| `ffmpeg` | any | `sudo apt install ffmpeg` |
| `yq` | v4+ | `sudo snap install yq` |
| `bash` | 4.0+ | pre-installed on most Linux/WSL |

---

## License

MIT — do whatever you want with it.

---

<div align="center">

*Built because copy-pasting yt-dlp commands for 30 videos gets old fast.*

</div>
