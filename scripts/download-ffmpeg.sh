#!/bin/bash

# Build FFmpeg from source for embedding (LGPL-compliant build)
#
# IMPORTANT: This script is for NON-App Store builds only!
# For App Store distribution, use: wails build -tags appstore
# which uses Apple's AVFoundation instead of FFmpeg.
#
# This script compiles FFmpeg from source under LGPL 2.1+ license.
# We explicitly avoid --enable-gpl and --enable-nonfree to ensure LGPL compliance.
# You must redistribute the FFmpeg source code (including any modifications) with your app.
# See: https://ffmpeg.org/legal.html
#
# The source code is saved alongside the binaries for redistribution compliance.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/../pkg/ffmpeg/binaries"
FFMPEG_VERSION="8.0.1"
FFMPEG_SOURCE_URL="https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz"

# Number of parallel jobs for compilation
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Create platform directories
mkdir -p "$BINARIES_DIR/darwin_arm64"
mkdir -p "$BINARIES_DIR/darwin_amd64"
mkdir -p "$BINARIES_DIR/linux_amd64"
mkdir -p "$BINARIES_DIR/windows_amd64"
mkdir -p "$BINARIES_DIR/source"

echo "=============================================="
echo "FFmpeg Source Build Script (LGPL-compliant)"
echo "=============================================="
echo ""
echo "Version: $FFMPEG_VERSION"
echo "Parallel jobs: $JOBS"
echo ""

# Check for required build tools
check_build_deps() {
    local missing=()
    
    for cmd in curl tar make; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Error: Missing required tools: ${missing[*]}"
        echo "Please install them before running this script."
        exit 1
    fi
    
    # Check for C compiler
    if ! command -v gcc &> /dev/null && ! command -v clang &> /dev/null; then
        echo "Error: No C compiler found. Please install gcc or clang."
        exit 1
    fi
}

# Download and extract FFmpeg source
# Note: Status messages go to stderr, only the path goes to stdout
download_source() {
    local source_dir="$BINARIES_DIR/source/ffmpeg-${FFMPEG_VERSION}"
    
    if [ -d "$source_dir" ]; then
        echo "Source already exists at: $source_dir" >&2
        echo "$source_dir"
        return 0
    fi
    
    echo "Downloading FFmpeg ${FFMPEG_VERSION} source..." >&2
    
    local temp_dir=$(mktemp -d)
    local tarball="$temp_dir/ffmpeg-${FFMPEG_VERSION}.tar.xz"
    
    curl -L "$FFMPEG_SOURCE_URL" -o "$tarball" --progress-bar
    
    echo "Extracting source..." >&2
    tar -xf "$tarball" -C "$BINARIES_DIR/source"
    
    rm -rf "$temp_dir"
    
    # Save source tarball for redistribution
    echo "Saving source tarball for LGPL redistribution..." >&2
    curl -L "$FFMPEG_SOURCE_URL" -o "$BINARIES_DIR/source/ffmpeg-${FFMPEG_VERSION}.tar.xz" --progress-bar
    
    echo "$source_dir"
}

# Common configure options for LGPL-compliant build
# We explicitly DO NOT use --enable-gpl or --enable-nonfree
# NOTE: libx264 and libx265 are GPL-licensed and CANNOT be used in LGPL builds
# We use LGPL/BSD-compatible encoders: mpeg4, libvpx, libaom
get_configure_opts() {
    local extra_opts="$1"
    
    cat << EOF
--disable-doc
--disable-debug
--disable-shared
--enable-static
--enable-pic
--disable-programs
--enable-ffmpeg
--disable-ffplay
--disable-ffprobe
--disable-network
--disable-autodetect
--enable-small
--enable-protocol=file
--enable-demuxer=mov,matroska,avi,mp4,webm,image2,gif,apng,png_pipe,jpeg_pipe,webp_pipe,bmp_pipe,tiff_pipe
--enable-muxer=mov,matroska,mp4,webm,gif,apng,image2,mjpeg,png
--enable-decoder=h264,hevc,vp8,vp9,av1,mpeg4,mjpeg,png,gif,webp,bmp,tiff,rawvideo,pcm_s16le,pcm_s24le,pcm_s32le,aac,mp3,opus,vorbis,flac
--enable-encoder=mpeg4,libvpx_vp8,libvpx_vp9,libaom_av1,mjpeg,png,gif,rawvideo,pcm_s16le,aac,libopus,libvorbis
--enable-parser=h264,hevc,vp8,vp9,av1,mpeg4video,mjpeg,png,gif
--enable-filter=scale,format,fps,null,copy,pad,crop,transpose,hflip,vflip
--enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,vp9_superframe
$extra_opts
EOF
}

# Build FFmpeg for macOS (native or cross-compile)
build_macos() {
    local arch=$1
    local dest_dir="$BINARIES_DIR/darwin_$arch"
    local source_dir=$(download_source)
    local build_dir="$source_dir/build_darwin_$arch"
    
    echo ""
    echo "Building FFmpeg for macOS $arch..."
    echo "----------------------------------------"
    
    # Check if we're on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "  ⚠ Cross-compiling for macOS from non-macOS is not supported."
        echo "  Skipping darwin_$arch..."
        return 1
    fi
    
    # Set architecture-specific flags
    local arch_flags=""
    local target_arch=""
    case $arch in
        arm64)
            arch_flags="--arch=aarch64 --enable-cross-compile"
            target_arch="arm64"
            ;;
        amd64)
            arch_flags="--arch=x86_64"
            target_arch="x86_64"
            ;;
    esac
    
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # Check for required libraries (install via Homebrew if needed)
    local extra_opts=""
    local cflags="-arch $target_arch"
    local ldflags="-arch $target_arch"
    
    # For external libraries, we ONLY use LGPL-compatible libraries
    # NOTE: libx264 and libx265 are GPL-licensed and are NOT supported
    # For H.264/HEVC output, users should use the App Store build (AVFoundation)
    # or accept MPEG-4/VP9/AV1 as alternatives
    
    echo "  LGPL-compliant build (no GPL components)"
    echo "  H.264/HEVC encoding not available (use VP9/AV1/MPEG4 instead)"
    echo ""
    
    if pkg-config --exists vpx 2>/dev/null; then
        extra_opts="$extra_opts --enable-libvpx"
        echo "  Found libvpx"
    else
        echo "  libvpx not found - VP8/VP9 encoding disabled"
        extra_opts="$extra_opts --disable-encoder=libvpx_vp8 --disable-encoder=libvpx_vp9"
    fi
    
    if pkg-config --exists 'aom >= 2.0.0' 2>/dev/null; then
        extra_opts="$extra_opts --enable-libaom"
        echo "  Found libaom (>= 2.0.0)"
    else
        echo "  libaom >= 2.0.0 not found - AV1 encoding disabled"
        extra_opts="$extra_opts --disable-encoder=libaom_av1"
    fi
    
    if pkg-config --exists opus 2>/dev/null; then
        extra_opts="$extra_opts --enable-libopus"
        echo "  Found libopus"
    else
        echo "  libopus not found - Opus encoding disabled"
        extra_opts="$extra_opts --disable-encoder=libopus"
    fi
    
    if pkg-config --exists vorbis 2>/dev/null; then
        extra_opts="$extra_opts --enable-libvorbis"
        echo "  Found libvorbis"
    else
        echo "  libvorbis not found - Vorbis encoding disabled"
        extra_opts="$extra_opts --disable-encoder=libvorbis"
    fi
    
    echo ""
    echo "  Configuring..."
    
    # Configure FFmpeg
    local configure_opts=$(get_configure_opts "$extra_opts")
    
    "$source_dir/configure" \
        --prefix="$build_dir/install" \
        --target-os=darwin \
        $arch_flags \
        --extra-cflags="$cflags" \
        --extra-ldflags="$ldflags" \
        $configure_opts \
        > configure.log 2>&1 || {
            echo "  ✗ Configure failed. See: $build_dir/configure.log"
            return 1
        }
    
    echo "  Compiling (this may take a while)..."
    
    make -j$JOBS > build.log 2>&1 || {
        echo "  ✗ Build failed. See: $build_dir/build.log"
        return 1
    }
    
    # Copy the binary
    if [ -f "ffmpeg" ]; then
        cp "ffmpeg" "$dest_dir/ffmpeg"
        chmod +x "$dest_dir/ffmpeg"
        
        # Strip debug symbols to reduce size
        strip "$dest_dir/ffmpeg" 2>/dev/null || true
        
        local size=$(du -h "$dest_dir/ffmpeg" | cut -f1)
        echo "  ✓ macOS $arch FFmpeg built successfully ($size)"
    else
        echo "  ✗ ffmpeg binary not found after build"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
}

# Build FFmpeg for Linux
build_linux() {
    local arch=$1
    local dest_dir="$BINARIES_DIR/linux_$arch"
    local source_dir=$(download_source)
    local build_dir="$source_dir/build_linux_$arch"
    
    echo ""
    echo "Building FFmpeg for Linux $arch..."
    echo "----------------------------------------"
    
    # Check if we're on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        echo "  ⚠ Cross-compiling for Linux from non-Linux is not fully supported."
        echo "  Attempting build anyway..."
    fi
    
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    local extra_opts=""
    
    # LGPL-compliant build - no GPL libraries (x264, x265)
    echo "  LGPL-compliant build (no GPL components)"
    
    if pkg-config --exists vpx 2>/dev/null; then
        extra_opts="$extra_opts --enable-libvpx"
    else
        extra_opts="$extra_opts --disable-encoder=libvpx_vp8 --disable-encoder=libvpx_vp9"
    fi
    
    if pkg-config --exists 'aom >= 2.0.0' 2>/dev/null; then
        extra_opts="$extra_opts --enable-libaom"
    else
        extra_opts="$extra_opts --disable-encoder=libaom_av1"
    fi
    
    if pkg-config --exists opus 2>/dev/null; then
        extra_opts="$extra_opts --enable-libopus"
    else
        extra_opts="$extra_opts --disable-encoder=libopus"
    fi
    
    if pkg-config --exists vorbis 2>/dev/null; then
        extra_opts="$extra_opts --enable-libvorbis"
    else
        extra_opts="$extra_opts --disable-encoder=libvorbis"
    fi
    
    echo "  Configuring..."
    
    local configure_opts=$(get_configure_opts "$extra_opts")
    
    "$source_dir/configure" \
        --prefix="$build_dir/install" \
        --target-os=linux \
        --arch=x86_64 \
        $configure_opts \
        > configure.log 2>&1 || {
            echo "  ✗ Configure failed. See: $build_dir/configure.log"
            return 1
        }
    
    echo "  Compiling (this may take a while)..."
    
    make -j$JOBS > build.log 2>&1 || {
        echo "  ✗ Build failed. See: $build_dir/build.log"
        return 1
    }
    
    if [ -f "ffmpeg" ]; then
        cp "ffmpeg" "$dest_dir/ffmpeg"
        chmod +x "$dest_dir/ffmpeg"
        strip "$dest_dir/ffmpeg" 2>/dev/null || true
        
        local size=$(du -h "$dest_dir/ffmpeg" | cut -f1)
        echo "  ✓ Linux $arch FFmpeg built successfully ($size)"
    else
        echo "  ✗ ffmpeg binary not found after build"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
}

# Build FFmpeg for Windows (cross-compile with MinGW)
build_windows() {
    local arch=$1
    local dest_dir="$BINARIES_DIR/windows_$arch"
    local source_dir=$(download_source)
    local build_dir="$source_dir/build_windows_$arch"
    
    echo ""
    echo "Building FFmpeg for Windows $arch..."
    echo "----------------------------------------"
    
    # Check for MinGW cross-compiler
    local cross_prefix=""
    if command -v x86_64-w64-mingw32-gcc &> /dev/null; then
        cross_prefix="x86_64-w64-mingw32-"
    elif command -v mingw-w64-gcc &> /dev/null; then
        cross_prefix="mingw-w64-"
    else
        echo "  ⚠ MinGW cross-compiler not found."
        echo "  Install with: brew install mingw-w64 (macOS) or apt install mingw-w64 (Linux)"
        echo "  Skipping windows_$arch..."
        return 1
    fi
    
    mkdir -p "$build_dir"
    cd "$build_dir"
    
    # LGPL-compliant build - use only built-in encoders for Windows cross-compile
    local extra_opts="--disable-encoder=libvpx_vp8 --disable-encoder=libvpx_vp9 --disable-encoder=libaom_av1 --disable-encoder=libopus --disable-encoder=libvorbis"
    
    echo "  LGPL-compliant build (minimal encoders for cross-compile)"
    echo "  Configuring for cross-compilation..."
    
    local configure_opts=$(get_configure_opts "$extra_opts")
    
    "$source_dir/configure" \
        --prefix="$build_dir/install" \
        --target-os=mingw32 \
        --arch=x86_64 \
        --cross-prefix="$cross_prefix" \
        --enable-cross-compile \
        $configure_opts \
        > configure.log 2>&1 || {
            echo "  ✗ Configure failed. See: $build_dir/configure.log"
            return 1
        }
    
    echo "  Compiling (this may take a while)..."
    
    make -j$JOBS > build.log 2>&1 || {
        echo "  ✗ Build failed. See: $build_dir/build.log"
        return 1
    }
    
    if [ -f "ffmpeg.exe" ]; then
        cp "ffmpeg.exe" "$dest_dir/ffmpeg.exe"
        ${cross_prefix}strip "$dest_dir/ffmpeg.exe" 2>/dev/null || true
        
        local size=$(du -h "$dest_dir/ffmpeg.exe" | cut -f1)
        echo "  ✓ Windows $arch FFmpeg built successfully ($size)"
    else
        echo "  ✗ ffmpeg.exe not found after build"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
}

# Print help
print_help() {
    echo "Usage: $0 [OPTIONS] [PLATFORMS...]"
    echo ""
    echo "Build FFmpeg from source for embedding (LGPL-compliant)"
    echo ""
    echo "Options:"
    echo "  --help, -h      Show this help message"
    echo "  --deps          Show required dependencies"
    echo "  --clean         Clean build directories before building"
    echo ""
    echo "Platforms:"
    echo "  darwin_arm64    macOS Apple Silicon"
    echo "  darwin_amd64    macOS Intel"
    echo "  linux_amd64     Linux x86_64"
    echo "  windows_amd64   Windows x86_64 (requires MinGW)"
    echo ""
    echo "If no platforms are specified, builds for current platform only."
    echo ""
    echo "Examples:"
    echo "  $0                      # Build for current platform"
    echo "  $0 darwin_arm64         # Build for macOS ARM64 only"
    echo "  $0 darwin_arm64 darwin_amd64  # Build for both macOS architectures"
    echo ""
    echo "Required dependencies (install via Homebrew on macOS):"
    echo "  brew install nasm yasm pkg-config"
    echo ""
    echo "Optional LGPL-compatible dependencies for better codec support:"
    echo "  brew install libvpx aom opus libvorbis"
    echo ""
    echo "NOTE: libx264 and libx265 are GPL-licensed and NOT supported in LGPL builds."
    echo "For H.264/HEVC encoding, use the App Store build with AVFoundation."
    echo ""
    echo "For Windows cross-compilation:"
    echo "  brew install mingw-w64"
}

# Print dependencies
print_deps() {
    echo "Required build dependencies:"
    echo ""
    echo "macOS (Homebrew):"
    echo "  brew install nasm yasm pkg-config"
    echo ""
    echo "Optional LGPL-compatible codecs:"
    echo "  brew install libvpx aom opus libvorbis"
    echo ""
    echo "NOTE: libx264 and libx265 are GPL-licensed and NOT supported."
    echo "This ensures the build remains LGPL-compliant for commercial use."
    echo "For H.264/HEVC encoding, use the App Store build with AVFoundation."
    echo ""
    echo "For Windows cross-compilation:"
    echo "  brew install mingw-w64"
    echo ""
    echo "Linux (apt):"
    echo "  sudo apt install build-essential nasm yasm pkg-config"
    echo "  sudo apt install libvpx-dev libaom-dev libopus-dev libvorbis-dev"
    echo ""
    echo "For Windows cross-compilation on Linux:"
    echo "  sudo apt install mingw-w64"
}

# Clean build directories
clean_builds() {
    echo "Cleaning build directories..."
    local source_dir="$BINARIES_DIR/source/ffmpeg-${FFMPEG_VERSION}"
    if [ -d "$source_dir" ]; then
        rm -rf "$source_dir"/build_* 2>/dev/null || true
        echo "  ✓ Cleaned build directories"
    fi
}

# Detect current platform
detect_platform() {
    local os=$(uname -s)
    local arch=$(uname -m)
    
    case "$os" in
        Darwin)
            case "$arch" in
                arm64) echo "darwin_arm64" ;;
                x86_64) echo "darwin_amd64" ;;
            esac
            ;;
        Linux)
            case "$arch" in
                x86_64) echo "linux_amd64" ;;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows_amd64"
            ;;
    esac
}

# Main execution
main() {
    local clean=false
    local platforms=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                print_help
                exit 0
                ;;
            --deps)
                print_deps
                exit 0
                ;;
            --clean)
                clean=true
                shift
                ;;
            darwin_arm64|darwin_amd64|linux_amd64|windows_amd64)
                platforms+=("$1")
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Check build dependencies
    check_build_deps
    
    # Clean if requested
    if [ "$clean" = true ]; then
        clean_builds
    fi
    
    # Default to current platform if none specified
    if [ ${#platforms[@]} -eq 0 ]; then
        local current=$(detect_platform)
        if [ -n "$current" ]; then
            platforms=("$current")
            echo "Building for current platform: $current"
        else
            echo "Could not detect current platform"
            exit 1
        fi
    fi
    
    # Download source first
    download_source > /dev/null
    
    # Build for each platform
    local success=0
    local failed=0
    
    for platform in "${platforms[@]}"; do
        case $platform in
            darwin_arm64)
                if build_macos "arm64"; then
                    ((success++))
                else
                    ((failed++))
                fi
                ;;
            darwin_amd64)
                if build_macos "amd64"; then
                    ((success++))
                else
                    ((failed++))
                fi
                ;;
            linux_amd64)
                if build_linux "amd64"; then
                    ((success++))
                else
                    ((failed++))
                fi
                ;;
            windows_amd64)
                if build_windows "amd64"; then
                    ((success++))
                else
                    ((failed++))
                fi
                ;;
        esac
    done
    
    echo ""
    echo "=============================================="
    echo "Build Summary"
    echo "=============================================="
    echo "Successful: $success"
    echo "Failed: $failed"
    echo ""
    echo "Binaries are in: $BINARIES_DIR"
    echo ""
    echo "Source code (for LGPL redistribution) is in:"
    echo "  $BINARIES_DIR/source/ffmpeg-${FFMPEG_VERSION}.tar.xz"
    echo ""
    echo "To build with embedded FFmpeg:"
    echo "  wails build -tags embed_ffmpeg"
    echo ""
    echo "Binary sizes:"
    du -sh "$BINARIES_DIR"/*/* 2>/dev/null | grep -v source || echo "  (no binaries found)"
    echo ""
    echo "IMPORTANT: For LGPL compliance, you must redistribute the FFmpeg"
    echo "source code with your application. The source tarball is saved at:"
    echo "  $BINARIES_DIR/source/ffmpeg-${FFMPEG_VERSION}.tar.xz"
}

main "$@"
