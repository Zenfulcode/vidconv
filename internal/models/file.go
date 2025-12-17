package models

// FileType represents the type of file (video or image)
type FileType string

const (
	FileTypeVideo   FileType = "video"
	FileTypeImage   FileType = "image"
	FileTypeUnknown FileType = "unknown"
)

// FileInfo contains information about a file
type FileInfo struct {
	Path      string   `json:"path"`
	Name      string   `json:"name"`
	Extension string   `json:"extension"`
	Size      int64    `json:"size"`
	Type      FileType `json:"type"`
}

// VideoFormats lists supported video formats
var VideoFormats = map[string]bool{
	".mp4":  true,
	".webm": true,
	".avi":  true,
	".mkv":  true,
	".mov":  true,
	".wmv":  true,
	".flv":  true,
	".m4v":  true,
	".mpeg": true,
	".mpg":  true,
	".3gp":  true,
	".mts":  true,
	".m2ts": true,
	".ts":   true,
	".vob":  true,
	".ogv":  true,
	".rm":   true,
	".rmvb": true,
	".asf":  true,
	".divx": true,
	".f4v":  true,
}

// ImageFormats lists supported image formats
var ImageFormats = map[string]bool{
	".png":  true,
	".jpg":  true,
	".jpeg": true,
	".webp": true,
	".gif":  true,
	".bmp":  true,
	".tiff": true,
	".tif":  true,
	".ico":  true,
	".svg":  true,
}

// VideoOutputFormats lists available output formats for videos
var VideoOutputFormats = []string{
	"mp4",
	"webm",
	"avi",
	"mkv",
	"mov",
	"gif",
}

// ImageOutputFormats lists available output formats for images
var ImageOutputFormats = []string{
	"png",
	"jpg",
	"jpeg",
	"webp",
	"gif",
	"bmp",
	"tiff",
}

// GetFileType returns the type of file based on extension
func GetFileType(extension string) FileType {
	if VideoFormats[extension] {
		return FileTypeVideo
	}
	if ImageFormats[extension] {
		return FileTypeImage
	}
	return FileTypeUnknown
}

// GetOutputFormats returns available output formats for a given file type
func GetOutputFormats(fileType FileType) []string {
	switch fileType {
	case FileTypeVideo:
		return VideoOutputFormats
	case FileTypeImage:
		return ImageOutputFormats
	default:
		return []string{}
	}
}
