#!/usr/bin/env bash
# One-click Python environment check and setup for macOS / Linux

echo "[KIRI-Skill] Checking Python environment..."

if command -v python3 >/dev/null 2>&1; then
    echo "[OK] Python 3 is already installed: $(python3 --version)"
    exit 0
fi

echo "[INFO] Python 3 not detected. Attempting setup based on OS..."

OS="$(uname -s)"
case "$OS" in
    Darwin)
        echo "[INFO] Detected macOS. Checking Homebrew or Xcode Command Line Tools..."
        if command -v brew >/dev/null 2>&1; then
            echo "[INFO] Installing python3 via Homebrew..."
            brew install python3
        else
            echo "[INFO] Triggering Xcode Command Line Tools install..."
            xcode-select --install
            echo "Please follow the on-screen prompt to complete the installation."
        fi
        ;;
    Linux)
        if command -v apt-get >/dev/null 2>&1; then
            echo "[INFO] Detected Debian/Ubuntu. Installing python3..."
            sudo apt-get update && sudo apt-get install -y python3
        elif command -v dnf >/dev/null 2>&1; then
            echo "[INFO] Detected Fedora/RHEL. Installing python3..."
            sudo dnf install -y python3
        elif command -v pacman >/dev/null 2>&1; then
            echo "[INFO] Detected Arch Linux. Installing python..."
            sudo pacman -S --noconfirm python
        else
            echo "[WARN] Unsupported package manager. Please install Python 3 manually from https://www.python.org/"
            exit 1
        fi
        ;;
    *)
        echo "[WARN] Unknown operating system ($OS). Please install Python 3 from https://www.python.org/"
        exit 1
        ;;
esac

if command -v python3 >/dev/null 2>&1; then
    echo "[SUCCESS] Python 3 is now available: $(python3 --version)"
    exit 0
else
    echo "[WARN] Installation in progress or requires terminal restart."
    exit 1
fi
