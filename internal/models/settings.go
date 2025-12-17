package models

import (
	"gorm.io/gorm"
)

// Setting represents a user setting stored in the database
type Setting struct {
	gorm.Model
	Key   string `json:"key" gorm:"uniqueIndex;not null"`
	Value string `json:"value" gorm:"not null"`
}

// SettingKey constants for common settings
const (
	SettingLastOutputDir   = "last_output_directory"
	SettingDefaultNaming   = "default_naming_mode"
	SettingDefaultMakeCopy = "default_make_copies"
	SettingTheme           = "theme"
)

// UserSettings represents the user's preferences
type UserSettings struct {
	LastOutputDirectory string         `json:"lastOutputDirectory"`
	DefaultNamingMode   FileNamingMode `json:"defaultNamingMode"`
	DefaultMakeCopies   bool           `json:"defaultMakeCopies"`
	Theme               string         `json:"theme"`
}

// DefaultUserSettings returns the default user settings
func DefaultUserSettings() UserSettings {
	return UserSettings{
		LastOutputDirectory: "",
		DefaultNamingMode:   NamingModeOriginal,
		DefaultMakeCopies:   true,
		Theme:               "system",
	}
}
