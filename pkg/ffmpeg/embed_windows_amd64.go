//go:build embed_ffmpeg && windows && amd64

package ffmpeg

import (
	"embed"
)

//go:embed binaries/windows_amd64/ffmpeg.exe
var embeddedBinary embed.FS

const embeddedBinaryPath = "binaries/windows_amd64/ffmpeg.exe"
const embeddedBinaryName = "ffmpeg.exe"
