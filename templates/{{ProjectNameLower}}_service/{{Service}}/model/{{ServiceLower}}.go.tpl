package model

import (
	"time"

	"gorm.io/gorm"
)

type {{ToUpperFirst(.Table.Name)}}Model struct {
	Id        int64           `json:"id" gorm:"primaryKey"`
{{range $field := .Ast.Table.Fields}}
	{{ToUpperFirst($field.Name)}} {{if $field.IsNull}}}*{{end}}{{ToSnakeCase($field.Type)}} `json:"{{ToSnakeCase($field.Name)}}" gorm:"{GormAnnotations($field)}}"`
{{end}}
	CreatedAt *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func (SampleModel) TableName() string {
	return "samples"
}
