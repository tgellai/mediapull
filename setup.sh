#!/bin/bash

# ============================================================
# mediapull — One-time setup script
# Run once: bash setup.sh
# ============================================================

PROJECT_DIR="$HOME/mediapull"

echo "=== mediapull setup ==="
echo ""

# 1. Directory structure
echo "[1/6] Creating directory structure..."
mkdir -p "$PROJECT_DIR"/{bin,config,input,output}
echo "      OK: $PROJECT_DIR/{bin,config,input,output}"

# 2. Copy scripts + symlink
echo "[2/6] Copying scripts to bin/..."
SCRIPT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_SOURCE/mediapull.sh" "$PROJECT_DIR/bin/"
cp "$SCRIPT_SOURCE/mediapull_completion.sh" "$PROJECT_DIR/bin/"
cp "$SCRIPT_SOURCE/config.yaml" "$PROJECT_DIR/config/"
chmod +x "$PROJECT_DIR/bin/mediapull.sh"

# Symlink: mediapull → mediapull.sh
ln -sf "$PROJECT_DIR/bin/mediapull.sh" "$PROJECT_DIR/bin/mediapull"
echo "      OK (symlink: mediapull → mediapull.sh)"

# 3. Install dependencies
echo "[3/6] Checking dependencies..."

# ffmpeg
if command -v ffmpeg &>/dev/null; then
    echo "      SKIP: ffmpeg already installed"
else
    echo "      Installing ffmpeg..."
    sudo apt update -qq && sudo apt install ffmpeg -y
    echo "      OK: ffmpeg"
fi

# yt-dlp
if command -v yt-dlp &>/dev/null; then
    echo "      SKIP: yt-dlp already installed"
else
    echo "      Installing yt-dlp..."
    sudo curl -sSL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
        -o /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    echo "      OK: yt-dlp"
fi

# yq
if command -v yq &>/dev/null; then
    echo "      SKIP: yq already installed ($(yq --version))"
else
    echo "      Installing yq via snap..."
    sudo snap install yq
    echo "      OK: yq"
fi

# 4. PATH + completion in ~/.bashrc
echo "[4/6] Updating ~/.bashrc..."
PATH_LINE="export PATH=\"\$HOME/mediapull/bin:\$PATH\""
COMPLETION_LINE="source \"\$HOME/mediapull/bin/mediapull_completion.sh\""
COMPLETE_LINE="complete -F _mediapull_completion mediapull"

if ! grep -qF "mediapull/bin" ~/.bashrc; then
    {
        echo ""
        echo "# mediapull"
        echo "$PATH_LINE"
        echo "$COMPLETION_LINE"
        echo "$COMPLETE_LINE"
    } >> ~/.bashrc
    echo "      OK: ~/.bashrc updated"
else
    echo "      SKIP: already in ~/.bashrc"
fi

# 5. Activate in current session
echo "[5/6] Activating in current session..."
export PATH="$PROJECT_DIR/bin:$PATH"
# shellcheck disable=SC1090
source "$PROJECT_DIR/bin/mediapull_completion.sh"
complete -F _mediapull_completion mediapull
echo "      OK"

# 6. Verify
echo "[6/6] Verifying installation..."
ALL_OK=true
for cmd in ffmpeg yt-dlp yq mediapull; do
    if command -v "$cmd" &>/dev/null; then
        echo "      OK: $cmd"
    else
        echo "      FAIL: $cmd not found!"
        ALL_OK=false
    fi
done

echo ""
if $ALL_OK; then
    echo "=== Setup complete! ==="
else
    echo "=== Setup finished with errors — check FAIL lines above ==="
fi

echo ""
echo "Next steps:"
echo "  1. Copy your URL list to input/:"
echo "     cp /path/to/your_links.md ~/mediapull/input/"
echo ""
echo "  2. Open a new terminal, then run:"
echo "     mediapull [SPACE] [TAB][TAB]"
echo ""
echo "  3. Edit your defaults anytime:"
echo "     nano ~/mediapull/config/config.yaml"
