package model

import (
	"time"

	"gorm.io/gorm"
)

type SampleModel struct {
	Id        int64           `json:"id" gorm:"primaryKey"`
	Name      string          `json:"name" gorm:"unique"`
	IsVisible bool            `json:"isVisible" gorm:"default:true"`
	CreatedAt *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func (SampleModel) TableName() string {
	return "samples"
}
