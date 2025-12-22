//go:build darwin && appstore

package main

import (
	"zenfile/internal/logger"
	"zenfile/internal/services"
)

// initVideoConverter initializes the video converter for App Store builds (using AVFoundation)
func (a *App) initVideoConverter(log *logger.Logger) services.Converter {
	log.Info("app", "Using AVFoundation for video conversion (App Store build)")
	// Pass nil for ffmpeg parameter - AVFoundation doesn't need it
	return services.NewVideoConverter(nil, log)
}

// isFFmpegAvailable returns false for App Store builds (we use AVFoundation instead)
func (a *App) isFFmpegAvailable() bool {
	return true // AVFoundation is always available on macOS
}

// getConverterBackend returns the name of the converter backend
func (a *App) getConverterBackend() string {
	return "avfoundation"
}

// getConverterVersion returns the version of the converter backend
func (a *App) getConverterVersion() (string, error) {
	// AVFoundation doesn't have a version string like FFmpeg
	// Return the macOS version instead
	return "AVFoundation (macOS native)", nil
}
