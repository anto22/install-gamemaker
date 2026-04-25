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

set -e
set -o pipefail

# ────────────────────────────────────────────────────────────────
# 📦 Global variables
TMP_DIR="/tmp/gamemaker-installer"
BASE_URL="https://download.opr.gg/"
PKG_NAME="GameMaker.deb"

# ────────────────────────────────────────────────────────────────
# 🧠 Detect distro and architecture
ARCH="$(uname -m)"
DISTRO="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${ID:-unknown}"
fi

echo "→ Detected system: ${DISTRO^} ($ARCH)"
sleep 0.5

# ────────────────────────────────────────────────────────────────
# 🧭 Find latest GameMaker Beta dynamically
fetch_latest() {
    echo "→ Checking for the latest GameMaker Beta build..." >&2

    LATEST_FILE=$(curl -s -A "Mozilla/5.0" "$BASE_URL" \
        | grep -oE 'GameMaker-Beta-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.deb' \
        | sort -V \
        | tail -n 1)

    if [ -z "$LATEST_FILE" ]; then
        echo "⚠️ Could not detect version, using fallback..." >&2
        LATEST_FILE="GameMaker-Beta-2024.1400.5.1052.deb"
    fi

    echo "$LATEST_FILE"
}

# ────────────────────────────────────────────────────────────────
# 🌐 Download latest package
download_package() {
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"

    echo "→ Downloading from: $LATEST_URL"
    wget -q --show-progress "$LATEST_URL" -O "$PKG_NAME" || {
        echo "❌ Download failed. Check your internet connection."
        exit 1
    }
}

# ────────────────────────────────────────────────────────────────
# 🧰 Install required tools
install_tools() {
    echo "→ Checking required conversion tools..."
    case "$DISTRO" in
        fedora|rhel|centos|opensuse*)
            if ! command -v alien &>/dev/null; then
                echo "→ Installing Alien (Fedora/OpenSUSE)..."
                sudo dnf install -y alien rpm-build || sudo zypper install -y alien rpm-build || {
                    echo "⚠️ Could not install Alien."
                }
            fi
            ;;
        arch|manjaro|endeavouros)
            if ! command -v debtap &>/dev/null; then
                echo "→ Installing Debtap (Arch-based)..."
                sudo pacman -Syu --needed --noconfirm debtap || {
                    echo "⚠️ Could not install Debtap — fallback to manual extraction."
                }
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            echo "→ Debian-based system detected — no conversion tool required."
            ;;
        *)
            echo "⚠️ Unknown distro — skipping automatic tool install."
            ;;
    esac
}

# ────────────────────────────────────────────────────────────────
# 🧩 Manual extraction fallback
extract_manual() {
    echo "→ Performing manual extraction of GameMaker package..."
    mkdir -p "$TMP_DIR/extracted"
    ar x "$PKG_NAME" || { echo "❌ Failed to extract .deb archive"; exit 1; }
    tar -xf data.tar.* -C "$TMP_DIR/extracted"
    sudo cp -r "$TMP_DIR/extracted/opt/GameMaker-Beta" /opt/ || {
        echo "❌ Could not copy extracted files to /opt/"
        exit 1
    }
    echo "GameMaker manually installed to /opt/GameMaker-Beta"
}

# ────────────────────────────────────────────────────────────────
# 🧱 Install or convert depending on distro
install_gamemaker() {
    echo "→ Installing GameMaker Beta..."
    case "$DISTRO" in
        fedora|rhel|centos|opensuse*)
            if command -v alien &>/dev/null; then
                echo "→ Converting .deb → .rpm via Alien..."
                sudo alien -r "$PKG_NAME"
                RPM_FILE=$(ls GameMaker-Beta-*.rpm | head -n 1)
                sudo rpm -i --nodeps "$RPM_FILE"
            else
                extract_manual
            fi
            ;;
        arch|manjaro|endeavouros)
            if command -v debtap &>/dev/null; then
                echo "→ Converting .deb → .zst via Debtap..."
                yes | sudo debtap -q "$PKG_NAME"
                PKG_FILE=$(ls *.zst | head -n 1)
                sudo pacman -U --noconfirm "$PKG_FILE"
            else
                extract_manual
            fi
            ;;
        ubuntu|debian|linuxmint|pop)
            echo "→ Installing .deb directly..."
            sudo apt install -y "./$PKG_NAME"
            ;;
        *)
            echo "⚠️ Unsupported distro — fallback to manual extraction."
            extract_manual
            ;;
    esac
}

# ────────────────────────────────────────────────────────────────
# 🧩 Apply runtime patches
apply_fixes() {
    echo "→ Applying compatibility patches..."
    sudo mkdir -p /lib/x86_64-linux-gnu 2>/dev/null

    for lib in libbz2.so.1.0 libfreetype.so.6 libpng16.so.16 libharfbuzz.so.0 libz.so.1; do
        [ -e "/usr/lib64/$lib" ] && sudo ln -sf "/usr/lib64/$lib" "/lib/x86_64-linux-gnu/$lib"
    done

    FT_VENDOR="/opt/GameMaker-Beta/x86_64/Vendor/freetype/freetype-x86_64-ubuntu-Release"
    if [ -f "$FT_VENDOR/freetype.so" ]; then
        echo "→ Replacing vendor FreeType..."
        sudo mv "$FT_VENDOR/freetype.so" "$FT_VENDOR/freetype.so.bak" 2>/dev/null || true
        sudo ln -sf /usr/lib64/libfreetype.so.6 "$FT_VENDOR/freetype.so"
    fi
}

# ────────────────────────────────────────────────────────────────
# 🔄 Update mode
if [[ "$1" == "--update" ]]; then
    echo "→ Checking for updates..."
    INSTALLED_VER=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /opt/GameMaker-Beta/version.txt 2>/dev/null || echo "none")
    echo "Installed version: $INSTALLED_VER"
    echo "Latest version: $LATEST_FILE"

    if [[ "$LATEST_FILE" != *"$INSTALLED_VER"* ]]; then
        echo "→ Update available, downloading..."
        download_package
        install_gamemaker
        apply_fixes
        echo "$LATEST_FILE" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sudo tee /opt/GameMaker-Beta/version.txt >/dev/null
        echo "GameMaker Beta updated successfully!"
    else
        echo "Already up to date."
    fi
    exit 0
fi

# ────────────────────────────────────────────────────────────────
# Run full install
download_package
install_tools
install_gamemaker
apply_fixes

echo
echo "✅ GameMaker Beta installation complete!"
echo
