//go:build !embed_ffmpeg

package ffmpeg

// GetEmbeddedFFmpegPath returns an error when FFmpeg is not embedded.
// Build with -tags embed_ffmpeg to include embedded FFmpeg binaries.
func GetEmbeddedFFmpegPath(appDataDir string) (string, error) {
	return "", nil
}

// HasEmbeddedFFmpeg returns false when FFmpeg is not embedded.
// Build with -tags embed_ffmpeg to include embedded FFmpeg binaries.
func HasEmbeddedFFmpeg() bool {
	return false
}

// GetSupportedPlatforms returns an empty list when FFmpeg is not embedded.
// Build with -tags embed_ffmpeg to include embedded FFmpeg binaries.
func GetSupportedPlatforms() []string {
	return []string{}
}
