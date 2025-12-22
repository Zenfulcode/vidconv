# FFmpeg Binaries Directory

**⚠️ IMPORTANT: This is for NON-App Store builds only!**

For App Store distribution, use:

```bash
wails build -tags appstore
```

This uses Apple's native AVFoundation instead of FFmpeg, avoiding license conflicts.

---

Place FFmpeg binaries here for embedding into the application (Homebrew/direct distribution builds).

## License Compliance

FFmpeg is licensed under LGPL 2.1+ (or GPL if built with certain codecs).

When distributing with embedded FFmpeg, you must:

1. Use LGPL-compatible FFmpeg builds (not GPL)
2. Include license attribution (see THIRD_PARTY_LICENSES.md)
3. Make FFmpeg source code available to users
4. Allow users to replace the FFmpeg binary

See: https://ffmpeg.org/legal.html

## Directory Structure

```
binaries/
├── darwin_amd64/
│   └── ffmpeg          # macOS Intel
├── darwin_arm64/
│   └── ffmpeg          # macOS Apple Silicon
├── linux_amd64/
│   └── ffmpeg          # Linux 64-bit
└── windows_amd64/
    └── ffmpeg.exe      # Windows 64-bit
```

## Building with Embedded FFmpeg

To build with embedded FFmpeg binaries:

```bash
# Using wails
wails build -tags embed_ffmpeg

# Using go directly
go build -tags embed_ffmpeg
```

Without the `embed_ffmpeg` build tag, the application will use system FFmpeg.

## Download Links

You can download static FFmpeg builds from:

### macOS

- https://evermeet.cx/ffmpeg/ (Static builds for both Intel and Apple Silicon)
- https://www.osxexperts.net/ (Alternative source)

### Windows

- https://github.com/BtbN/FFmpeg-Builds/releases (GPL/LGPL builds)
- https://www.gyan.dev/ffmpeg/builds/ (Alternative source)

### Linux

- https://github.com/BtbN/FFmpeg-Builds/releases (Static builds)
- https://johnvansickle.com/ffmpeg/ (Alternative source)

## Notes

1. Make sure the binaries are executable on Unix systems:

   ```bash
   chmod +x binaries/darwin_*/ffmpeg
   chmod +x binaries/linux_*/ffmpeg
   ```

2. Use static builds to avoid dependency issues

3. The binaries will significantly increase the application size (~80-150MB per platform)

4. Consider using GPL builds if you need full codec support

5. The application will extract the binary to the user's app data directory at runtime
