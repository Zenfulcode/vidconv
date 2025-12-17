package models

import (
	"time"

	"gorm.io/gorm"
)

// ConversionStatus represents the status of a conversion job
type ConversionStatus string

const (
	StatusPending    ConversionStatus = "pending"
	StatusProcessing ConversionStatus = "processing"
	StatusCompleted  ConversionStatus = "completed"
	StatusFailed     ConversionStatus = "failed"
	StatusCancelled  ConversionStatus = "cancelled"
)

// Conversion represents a file conversion record in the database
type Conversion struct {
	gorm.Model
	InputPath    string           `json:"inputPath" gorm:"not null"`
	OutputPath   string           `json:"outputPath" gorm:"not null"`
	InputFormat  string           `json:"inputFormat" gorm:"not null"`
	OutputFormat string           `json:"outputFormat" gorm:"not null"`
	FileType     FileType         `json:"fileType" gorm:"not null"`
	FileSize     int64            `json:"fileSize"`
	OutputSize   int64            `json:"outputSize"`
	Status       ConversionStatus `json:"status" gorm:"not null;default:'pending'"`
	ErrorMessage string           `json:"errorMessage,omitempty"`
	Progress     float64          `json:"progress" gorm:"default:0"`
	StartedAt    *time.Time       `json:"startedAt,omitempty"`
	CompletedAt  *time.Time       `json:"completedAt,omitempty"`
}

// ConversionJob represents a conversion request from the frontend
type ConversionJob struct {
	InputPath       string `json:"inputPath"`
	OutputPath      string `json:"outputPath"`
	OutputFormat    string `json:"outputFormat"`
	OverwriteOutput bool   `json:"overwriteOutput"`
}

// ConversionResult represents the result of a conversion
type ConversionResult struct {
	Success      bool   `json:"success"`
	InputPath    string `json:"inputPath"`
	OutputPath   string `json:"outputPath"`
	OutputSize   int64  `json:"outputSize"`
	ErrorMessage string `json:"errorMessage,omitempty"`
	Duration     int64  `json:"duration"` // Duration in milliseconds
}

// ConversionProgress represents the progress of an ongoing conversion
type ConversionProgress struct {
	ID        uint    `json:"id"`
	InputPath string  `json:"inputPath"`
	Progress  float64 `json:"progress"` // 0-100
	Status    string  `json:"status"`
}

// BatchConversionRequest represents a request to convert multiple files
type BatchConversionRequest struct {
	Files           []string       `json:"files"`
	OutputFormat    string         `json:"outputFormat"`
	OutputDirectory string         `json:"outputDirectory"`
	NamingMode      FileNamingMode `json:"namingMode"`
	CustomNames     []string       `json:"customNames,omitempty"`
	MakeCopies      bool           `json:"makeCopies"`
}

// FileNamingMode defines how output files should be named
type FileNamingMode string

const (
	NamingModeOriginal FileNamingMode = "original" // Keep original filename
	NamingModeCustom   FileNamingMode = "custom"   // Use custom names
)

// BatchConversionResult represents the result of a batch conversion
type BatchConversionResult struct {
	TotalFiles    int                `json:"totalFiles"`
	SuccessCount  int                `json:"successCount"`
	FailCount     int                `json:"failCount"`
	Results       []ConversionResult `json:"results"`
	TotalDuration int64              `json:"totalDuration"` // Total duration in milliseconds
}
