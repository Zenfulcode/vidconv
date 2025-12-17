package logger

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"time"
)

// Level represents the logging level
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

func (l Level) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// Logger handles application logging
type Logger struct {
	mu       sync.Mutex
	level    Level
	file     *os.File
	logger   *log.Logger
	filePath string
}

// New creates a new Logger instance
func New(filePath string, level Level) (*Logger, error) {
	// Ensure the directory exists
	dir := filepath.Dir(filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create log directory: %w", err)
	}

	// Open or create the log file
	file, err := os.OpenFile(filePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, fmt.Errorf("failed to open log file: %w", err)
	}

	// Write to both file and stdout
	multiWriter := io.MultiWriter(os.Stdout, file)
	logger := log.New(multiWriter, "", 0)

	return &Logger{
		level:    level,
		file:     file,
		logger:   logger,
		filePath: filePath,
	}, nil
}

// Close closes the log file
func (l *Logger) Close() error {
	l.mu.Lock()
	defer l.mu.Unlock()

	if l.file != nil {
		return l.file.Close()
	}
	return nil
}

// SetLevel sets the minimum logging level
func (l *Logger) SetLevel(level Level) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.level = level
}

// log writes a log entry at the specified level
func (l *Logger) log(level Level, component, format string, args ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()

	if level < l.level {
		return
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	message := fmt.Sprintf(format, args...)

	// Get caller information for DEBUG level
	var caller string
	if level == DEBUG {
		_, file, line, ok := runtime.Caller(2)
		if ok {
			caller = fmt.Sprintf(" (%s:%d)", filepath.Base(file), line)
		}
	}

	logLine := fmt.Sprintf("%s [%s] [%s]%s %s", timestamp, level.String(), component, caller, message)
	l.logger.Println(logLine)
}

// Debug logs a debug message
func (l *Logger) Debug(component, format string, args ...interface{}) {
	l.log(DEBUG, component, format, args...)
}

// Info logs an info message
func (l *Logger) Info(component, format string, args ...interface{}) {
	l.log(INFO, component, format, args...)
}

// Warn logs a warning message
func (l *Logger) Warn(component, format string, args ...interface{}) {
	l.log(WARN, component, format, args...)
}

// Error logs an error message
func (l *Logger) Error(component, format string, args ...interface{}) {
	l.log(ERROR, component, format, args...)
}

// WithComponent returns a ComponentLogger for a specific component
func (l *Logger) WithComponent(component string) *ComponentLogger {
	return &ComponentLogger{
		logger:    l,
		component: component,
	}
}

// ComponentLogger is a logger bound to a specific component
type ComponentLogger struct {
	logger    *Logger
	component string
}

// Debug logs a debug message
func (cl *ComponentLogger) Debug(format string, args ...interface{}) {
	cl.logger.Debug(cl.component, format, args...)
}

// Info logs an info message
func (cl *ComponentLogger) Info(format string, args ...interface{}) {
	cl.logger.Info(cl.component, format, args...)
}

// Warn logs a warning message
func (cl *ComponentLogger) Warn(format string, args ...interface{}) {
	cl.logger.Warn(cl.component, format, args...)
}

// Error logs an error message
func (cl *ComponentLogger) Error(format string, args ...interface{}) {
	cl.logger.Error(cl.component, format, args...)
}
