package model

import (
	"time"

	"gorm.io/gorm"
)

type OrganisationModel struct {
	Id        int64           `json:"id" gorm:"primaryKey"`
	Name      string          `json:"name" gorm:"unique"`
	CreatedAt *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func (OrganisationModel) TableName() string {
	return "organisations"
}
