//go:build embed_ffmpeg

package ffmpeg

import (
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"runtime"
	"sync"
)

var (
	extractedPath string
	extractOnce   sync.Once
	extractErr    error
)

// GetEmbeddedFFmpegPath extracts the embedded FFmpeg binary to the app data directory
// and returns the path to the extracted binary. The binary is only extracted once
// and cached for subsequent calls.
func GetEmbeddedFFmpegPath(appDataDir string) (string, error) {
	extractOnce.Do(func() {
		extractedPath, extractErr = extractFFmpeg(appDataDir)
	})
	return extractedPath, extractErr
}

// extractFFmpeg extracts the appropriate FFmpeg binary for the current platform
func extractFFmpeg(appDataDir string) (string, error) {
	// Check if the embedded binary exists
	file, err := embeddedBinary.Open(embeddedBinaryPath)
	if err != nil {
		return "", fmt.Errorf("embedded FFmpeg binary not found for %s/%s: %w", runtime.GOOS, runtime.GOARCH, err)
	}
	file.Close()

	// Create the bin directory in app data
	binDir := filepath.Join(appDataDir, "bin")
	if err := os.MkdirAll(binDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create bin directory: %w", err)
	}

	destPath := filepath.Join(binDir, embeddedBinaryName)

	// Check if we need to extract (binary doesn't exist or is outdated)
	if needsExtraction(destPath) {
		if err := extractBinary(destPath); err != nil {
			return "", err
		}
	}

	return destPath, nil
}

// needsExtraction checks if the binary needs to be extracted
func needsExtraction(destPath string) bool {
	destInfo, err := os.Stat(destPath)
	if os.IsNotExist(err) {
		return true
	}
	if err != nil {
		return true
	}

	// Get embedded file info
	embeddedFile, err := embeddedBinary.Open(embeddedBinaryPath)
	if err != nil {
		return true
	}
	defer embeddedFile.Close()

	embeddedInfo, err := embeddedFile.(fs.File).Stat()
	if err != nil {
		return true
	}

	// Re-extract if sizes differ (simple check for updates)
	return destInfo.Size() != embeddedInfo.Size()
}

// extractBinary extracts the embedded binary to the destination path
func extractBinary(destPath string) error {
	embeddedFile, err := embeddedBinary.Open(embeddedBinaryPath)
	if err != nil {
		return fmt.Errorf("failed to open embedded binary: %w", err)
	}
	defer embeddedFile.Close()

	// Create destination file with executable permissions
	destFile, err := os.OpenFile(destPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %w", err)
	}
	defer destFile.Close()

	// Copy the binary
	if _, err := io.Copy(destFile, embeddedFile); err != nil {
		return fmt.Errorf("failed to extract binary: %w", err)
	}

	return nil
}

// HasEmbeddedFFmpeg checks if there's an embedded FFmpeg binary for the current platform
func HasEmbeddedFFmpeg() bool {
	file, err := embeddedBinary.Open(embeddedBinaryPath)
	if err != nil {
		return false
	}
	file.Close()

	// Also check it's not an empty file
	info, err := fs.Stat(embeddedBinary, embeddedBinaryPath)
	if err != nil {
		return false
	}

	// FFmpeg binary should be at least 1MB
	return info.Size() > 1024*1024
}

// GetSupportedPlatforms returns the current platform (only one is embedded per build)
func GetSupportedPlatforms() []string {
	return []string{fmt.Sprintf("%s_%s", runtime.GOOS, runtime.GOARCH)}
}
