//go:build embed_ffmpeg && linux && amd64

package ffmpeg

import (
	"embed"
)

//go:embed binaries/linux_amd64/ffmpeg
var embeddedBinary embed.FS

const embeddedBinaryPath = "binaries/linux_amd64/ffmpeg"
const embeddedBinaryName = "ffmpeg"
