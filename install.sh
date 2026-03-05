#!/bin/bash

# Installation script for cursor theme

THEME_NAME="your-cursor-theme"
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/output"

# Install XCursor theme system-wide (requires sudo)
install_xcursor_system() {
    sudo mkdir -p "/usr/share/icons/${THEME_NAME}"
    sudo cp -r "${OUTPUT_DIR}/xcursor/cursors" "/usr/share/icons/${THEME_NAME}/"
    sudo cp "${OUTPUT_DIR}/xcursor/index.theme" "/usr/share/icons/${THEME_NAME}/"
    echo "XCursor theme installed system-wide"
}

# Install XCursor theme locally
install_xcursor_local() {
    mkdir -p "${HOME}/.icons/${THEME_NAME}"
    cp -r "${OUTPUT_DIR}/xcursor/cursors" "${HOME}/.icons/${THEME_NAME}/"
    cp "${OUTPUT_DIR}/xcursor/index.theme" "${HOME}/.icons/${THEME_NAME}/"
    echo "XCursor theme installed locally"
}

# Install Windows cursors
install_windows() {
    echo "Windows cursor files are in: ${OUTPUT_DIR}/windows/"
    echo "To install on Windows:"
    echo "1. Copy all .cur and .ani files to C:\\Windows\\Cursors\\"
    echo "2. Right-click the install.inf file and select 'Install'"
}

case "$1" in
    --system)
        install_xcursor_system
        ;;
    --local)
        install_xcursor_local
        ;;
    --windows)
        install_windows
        ;;
    *)
        echo "Usage: $0 [--system|--local|--windows]"
        ;;
esac
