package model

import (
	"time"

	"gorm.io/gorm"
)

type {{ToUpperFirst(.Table.Name)}}Model struct {
	Id        int64           `json:"id" gorm:"primaryKey"`
    {{GormFields(.Ast.Table.Fields)}}
	CreatedAt *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func (SampleModel) TableName() string {
	return "samples"
}
