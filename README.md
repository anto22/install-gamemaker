# install-gamemaker
Run GameMaker Beta natively on any Linux distro — no Flatpak, no container, just pure system magic 😎

# 🧩 GameMaker Beta Linux Installer

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Shell: Bash](https://img.shields.io/badge/shell-bash-blue.svg)
![Supported Distros](https://img.shields.io/badge/Distros-Fedora%20|%20Arch%20|%20Ubuntu%20|%20openSUSE-lightgrey.svg)

A **universal installation script** for the official **GameMaker Beta for Linux** from [YoYo Games](https://www.yoyogames.com/).

This script automatically downloads the latest `.deb` build from the **official server** (`https://download.opr.gg/`),  
installs conversion tools if needed, converts or extracts the package, and applies all required library patches  
to make it run perfectly on **non-Ubuntu systems** (Fedora, Arch, Manjaro, openSUSE, etc.).

---

## 🚀 Features

✅ Automatically downloads the latest GameMaker Beta version  
✅ Converts `.deb` → `.rpm` or `.zst` when needed  
✅ Installs `alien` / `debtap` automatically  
✅ Fixes missing Ubuntu-style library paths (`/lib/x86_64-linux-gnu`)  
✅ Patches broken `freetype.so` dependency  
✅ No Flatpak, no container, 100% native installation  
✅ Compatible with most modern distros

---

## 🧠 Supported Systems

| Distribution | Status | Conversion Tool |
|---------------|---------|-----------------|
| 🟢 Ubuntu / Debian / Mint / Pop!_OS | ✅ Works natively | (direct install) |
| 🟢 Fedora / RHEL / openSUSE | ✅ Works after conversion | `alien` |
| 🟢 Arch / Manjaro / EndeavourOS | ✅ Works after conversion | `debtap` |
| 🟡 Others (Void, NixOS, etc.) | ⚙️ Works via manual extraction | (fallback mode) |

---

## ⚙️ Installation

### 1️⃣ Clone the repository
```bash
git clone https://github.com/<ton-user>/GameMaker-Linux-Installer.git
cd GameMaker-Linux-Installer
