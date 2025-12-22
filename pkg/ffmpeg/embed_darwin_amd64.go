//go:build embed_ffmpeg && darwin && amd64

package ffmpeg

import (
	"embed"
)

//go:embed binaries/darwin_amd64/ffmpeg
var embeddedBinary embed.FS

const embeddedBinaryPath = "binaries/darwin_amd64/ffmpeg"
const embeddedBinaryName = "ffmpeg"
