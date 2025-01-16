package model

import (
	"generator/service/ast"
	"time"

	"gorm.io/gorm"
)

type ServiceModel struct {
	Id           int64           `json:"id" gorm:"primaryKey"`
	Name         string          `json:"name"`
	ProjectId    int             `json:"projectId" gorm:"not null;index:idx_service_project_id"`
	Description  string          `json:"description"`
	Multilingual bool            `json:"multilingual"`
	Ast          ast.Ast         `json:"ast" gorm:"serializer:json;type:jsonb"`
	CreatedAt    *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt    *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt    *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func (ServiceModel) TableName() string {
	return "services"
}
