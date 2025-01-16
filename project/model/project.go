package model

import (
	"generator/service/model"
	"time"

	"gorm.io/gorm"
)

type ProjectModel struct {
	Id          int64                `json:"id" gorm:"primaryKey"`
	Name        string               `json:"name"`
	UserId      int                  `json:"userId" gorm:"not null;index:idx_project_user_id"`
	Description string               `json:"description"`
	Services    []model.ServiceModel `json:"services" gorm:"foreignKey:ProjectId"`
	CreatedAt   *time.Time           `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt   *time.Time           `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt   *gorm.DeletedAt      `json:"-" swaggerignore:"true"`
}

func (ProjectModel) TableName() string {
	return "projects"
}
