//go:build embed_ffmpeg && darwin && arm64

package ffmpeg

import (
	"embed"
)

//go:embed binaries/darwin_arm64/ffmpeg
var embeddedBinary embed.FS

const embeddedBinaryPath = "binaries/darwin_arm64/ffmpeg"
const embeddedBinaryName = "ffmpeg"
