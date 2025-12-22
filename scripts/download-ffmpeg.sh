#!/bin/bash

# Download FFmpeg binaries for embedding (Homebrew/direct distribution builds only)
#
# IMPORTANT: This script is for NON-App Store builds only!
# For App Store distribution, use: wails build -tags appstore
# which uses Apple's AVFoundation instead of FFmpeg.
#
# FFmpeg is licensed under LGPL 2.1+ (or GPL if compiled with GPL components).
# Embedding FFmpeg in your application requires compliance with its license terms.
# See: https://ffmpeg.org/legal.html

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/../pkg/ffmpeg/binaries"

# Create platform directories
mkdir -p "$BINARIES_DIR/darwin_arm64"
mkdir -p "$BINARIES_DIR/darwin_amd64"
mkdir -p "$BINARIES_DIR/linux_amd64"
mkdir -p "$BINARIES_DIR/windows_amd64"

echo "Downloading FFmpeg binaries..."
echo ""

# Function to download and extract FFmpeg for macOS
download_macos() {
    local arch=$1
    local url=$2
    local dest_dir="$BINARIES_DIR/darwin_$arch"
    
    echo "Downloading FFmpeg for macOS $arch..."
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    
    # Download
    curl -L "$url" -o "$temp_dir/ffmpeg.7z" 2>/dev/null || curl -L "$url" -o "$temp_dir/ffmpeg.zip" 2>/dev/null
    
    # Extract based on file type
    if [ -f "$temp_dir/ffmpeg.7z" ]; then
        if command -v 7z &> /dev/null; then
            7z x "$temp_dir/ffmpeg.7z" -o"$temp_dir" -y > /dev/null
        else
            echo "  Error: 7z is required to extract macOS binaries. Install with: brew install p7zip"
            rm -rf "$temp_dir"
            return 1
        fi
    elif [ -f "$temp_dir/ffmpeg.zip" ]; then
        unzip -q "$temp_dir/ffmpeg.zip" -d "$temp_dir"
    fi
    
    # Find and move ffmpeg binary
    local ffmpeg_bin=$(find "$temp_dir" -name "ffmpeg" -type f ! -name "*.txt" | head -1)
    if [ -n "$ffmpeg_bin" ]; then
        cp "$ffmpeg_bin" "$dest_dir/ffmpeg"
        chmod +x "$dest_dir/ffmpeg"
        echo "  ✓ macOS $arch FFmpeg downloaded"
    else
        echo "  ✗ Could not find ffmpeg binary in download"
    fi
    
    rm -rf "$temp_dir"
}

# Function to download and extract FFmpeg for Linux
download_linux() {
    local arch=$1
    local dest_dir="$BINARIES_DIR/linux_$arch"
    
    echo "Downloading FFmpeg for Linux $arch..."
    
    # Use John Van Sickle's static builds
    local url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
    
    local temp_dir=$(mktemp -d)
    
    curl -L "$url" -o "$temp_dir/ffmpeg.tar.xz" 2>/dev/null
    
    tar -xf "$temp_dir/ffmpeg.tar.xz" -C "$temp_dir"
    
    local ffmpeg_bin=$(find "$temp_dir" -name "ffmpeg" -type f | head -1)
    if [ -n "$ffmpeg_bin" ]; then
        cp "$ffmpeg_bin" "$dest_dir/ffmpeg"
        chmod +x "$dest_dir/ffmpeg"
        echo "  ✓ Linux $arch FFmpeg downloaded"
    else
        echo "  ✗ Could not find ffmpeg binary in download"
    fi
    
    rm -rf "$temp_dir"
}

# Function to download and extract FFmpeg for Windows
download_windows() {
    local arch=$1
    local dest_dir="$BINARIES_DIR/windows_$arch"
    
    echo "Downloading FFmpeg for Windows $arch..."
    
    # Use gyan.dev builds (essentials version is smaller)
    local url="https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    
    local temp_dir=$(mktemp -d)
    
    curl -L "$url" -o "$temp_dir/ffmpeg.zip" 2>/dev/null
    
    unzip -q "$temp_dir/ffmpeg.zip" -d "$temp_dir"
    
    local ffmpeg_bin=$(find "$temp_dir" -name "ffmpeg.exe" -type f | head -1)
    if [ -n "$ffmpeg_bin" ]; then
        cp "$ffmpeg_bin" "$dest_dir/ffmpeg.exe"
        echo "  ✓ Windows $arch FFmpeg downloaded"
    else
        echo "  ✗ Could not find ffmpeg.exe in download"
    fi
    
    rm -rf "$temp_dir"
}

# Parse arguments
PLATFORMS=()
if [ $# -eq 0 ]; then
    PLATFORMS=("darwin_arm64" "darwin_amd64" "linux_amd64" "windows_amd64")
else
    PLATFORMS=("$@")
fi

for platform in "${PLATFORMS[@]}"; do
    case $platform in
        darwin_arm64)
            # evermeet.cx provides ARM64 builds
            download_macos "arm64" "https://evermeet.cx/ffmpeg/ffmpeg-7.1.1.zip"
            ;;
        darwin_amd64)
            # evermeet.cx also provides AMD64 builds
            download_macos "amd64" "https://evermeet.cx/ffmpeg/ffmpeg-7.1.1.zip"
            ;;
        linux_amd64)
            download_linux "amd64"
            ;;
        windows_amd64)
            download_windows "amd64"
            ;;
        *)
            echo "Unknown platform: $platform"
            echo "Supported platforms: darwin_arm64, darwin_amd64, linux_amd64, windows_amd64"
            ;;
    esac
done

echo ""
echo "Done! FFmpeg binaries are in: $BINARIES_DIR"
echo ""
echo "To build with embedded FFmpeg:"
echo "  wails build -tags embed_ffmpeg"
echo ""
echo "Binary sizes:"
du -sh "$BINARIES_DIR"/*/* 2>/dev/null || echo "  (no binaries found)"
