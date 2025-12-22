//go:build darwin && appstore

package config

// findFFmpeg returns an empty string for App Store builds
// since we use AVFoundation instead of FFmpeg
func findFFmpeg(dataDir string) string {
	return ""
}
