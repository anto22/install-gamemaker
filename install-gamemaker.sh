#!/usr/bin/env bash
#
# 🧩 Universal GameMaker Beta Installer for Linux
#
# Downloads the latest official GameMaker Beta .deb from https://download.opr.gg/,
# installs any required conversion tools (alien / debtap),
# converts or extracts it automatically for your distro,
# and applies compatibility patches for Fedora / Arch / other non-Ubuntu systems.
#
# Author : Anthony (2025)
# License: MIT — personal use only (downloads official binary from YoYo Games)
#
# Supported systems: Fedora, Arch, Manjaro, Ubuntu, Debian, Linux Mint, Pop!_OS, openSUSE
#

#!/usr/bin/env bash

set -e
set -o pipefail

# ─────────────────────────────────────────────
# 📦 Variables
TMP_DIR="/tmp/gamemaker-installer"
BASE_URL="https://download.opr.gg/"
PKG_NAME="GameMaker.deb"
FALLBACK_FILE="GameMaker-Beta-2024.1400.5.1052.deb"

# ─────────────────────────────────────────────
# 🧠 Détection système
ARCH="$(uname -m)"
DISTRO="unknown"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-unknown}"
fi

echo "→ Detected system: ${DISTRO^} ($ARCH)"
sleep 0.5

# ─────────────────────────────────────────────
# 🔎 Détection version (optionnelle)
fetch_latest() {
    curl -s -A "Mozilla/5.0" "$BASE_URL" \
        | grep -oE 'GameMaker-Beta-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.deb' \
        | sort -V \
        | tail -n 1 || true
}

LATEST_FILE="$(fetch_latest)"

if [ -z "$LATEST_FILE" ]; then
    echo "⚠️ Auto-detect failed (site changed or blocked)."
    echo "→ Using fallback version: $FALLBACK_FILE"
    LATEST_FILE="$FALLBACK_FILE"
fi

LATEST_URL="${BASE_URL}${LATEST_FILE}"

echo "→ Selected version: $LATEST_FILE"
echo "→ Download URL: $LATEST_URL"

# ─────────────────────────────────────────────
# 🌐 Download (FIX: curl au lieu de wget)
download_package() {
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"

    echo "→ Downloading..."

    if ! curl -L --progress-bar -A "Mozilla/5.0" "$LATEST_URL" -o "$PKG_NAME"; then
        echo "❌ Download failed (server / URL issue, not your internet)."
        echo

        read -p "👉 Enter a valid .deb URL manually: " MANUAL_URL

        if [ -z "$MANUAL_URL" ]; then
            echo "❌ No URL provided. Aborting."
            exit 1
        fi

        curl -L "$MANUAL_URL" -o "$PKG_NAME" || {
            echo "❌ Manual download failed."
            exit 1
        }
    fi
}

# ─────────────────────────────────────────────
# 🧰 Tools
install_tools() {
    echo "→ Checking required tools..."

    case "$DISTRO" in
        fedora|rhel|centos|opensuse*)
            command -v alien >/dev/null || sudo dnf install -y alien rpm-build || true
            ;;
        arch|manjaro|endeavouros|cachyos)
            command -v debtap >/dev/null || sudo pacman -S --noconfirm debtap || true
            ;;
        ubuntu|debian|linuxmint|pop)
            ;;
    esac
}

# ─────────────────────────────────────────────
# 📦 Extraction fallback
extract_manual() {
    echo "→ Manual extraction..."

    mkdir -p "$TMP_DIR/extracted"
    ar x "$PKG_NAME"
    tar -xf data.tar.* -C "$TMP_DIR/extracted"

    sudo cp -r "$TMP_DIR/extracted/opt/GameMaker-Beta" /opt/

    echo "→ Installed to /opt/GameMaker-Beta"
}

# ─────────────────────────────────────────────
# 🧱 Installation
install_gamemaker() {
    echo "→ Installing..."

    case "$DISTRO" in
        fedora|rhel|centos|opensuse*)
            if command -v alien &>/dev/null; then
                sudo alien -r "$PKG_NAME"
                sudo rpm -i --nodeps *.rpm
            else
                extract_manual
            fi
            ;;
        arch|manjaro|endeavouros|cachyos)
            if command -v debtap &>/dev/null; then
                yes | sudo debtap -q "$PKG_NAME"
                sudo pacman -U --noconfirm *.zst
            else
                extract_manual
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            sudo apt install -y "./$PKG_NAME"
            ;;
        *)
            extract_manual
            ;;
    esac
}

# ─────────────────────────────────────────────
# 🧩 Fixes runtime
apply_fixes() {
    echo "→ Applying fixes..."

    sudo mkdir -p /lib/x86_64-linux-gnu 2>/dev/null

    for lib in libbz2.so.1.0 libfreetype.so.6 libpng16.so.16 libharfbuzz.so.0 libz.so.1; do
        [ -e "/usr/lib64/$lib" ] && sudo ln -sf "/usr/lib64/$lib" "/lib/x86_64-linux-gnu/$lib"
    done

    FT_VENDOR="/opt/GameMaker-Beta/x86_64/Vendor/freetype/freetype-x86_64-ubuntu-Release"

    if [ -f "$FT_VENDOR/freetype.so" ]; then
        sudo mv "$FT_VENDOR/freetype.so" "$FT_VENDOR/freetype.so.bak" 2>/dev/null || true
        sudo ln -sf /usr/lib64/libfreetype.so.6 "$FT_VENDOR/freetype.so"
    fi
}
create_launcher() {
    echo "→ Creating desktop entry..."

    sudo tee /usr/share/applications/gamemaker-beta.desktop > /dev/null <<EOF
[Desktop Entry]
Name=GameMaker Beta
Exec=/opt/GameMaker-Beta/GameMaker
Icon=/opt/GameMaker-Beta/Assets/Linux/icon.png
Type=Application
Categories=Development;
EOF
}
# ─────────────────────────────────────────────
# 🚀 Exécution
download_package
install_tools
install_gamemaker
apply_fixes

echo
echo "✅ GameMaker Beta installation complete!"
