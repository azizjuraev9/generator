package model

import (
	"time"
    {{range _, $field := .Service.Ast.Table.Fields}}
    {{if $field.Relation != nil}}
    {{ToLowerFirst(toCamelCase($field.Relation.RefTable))}}Model "{{toSnakeCase(.Service.ProjectName)}}/{{toSnakeCase(.Service.Ast.Table.Name)}}/{{toSnakeCase($field.Relation.RefTable)}}/model"
    {{end}}
    {{end}}
	"gorm.io/gorm"
)

type {{ToUpperFirst(.Service.Ast.Table.Name)}}Model struct {
	Id        int64           `json:"id" gorm:"primaryKey"`
    {{GormFields(.Service.Ast.Table.Fields)}}
	CreatedAt *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func ({{ToUpperFirst(.Service.Ast.Table.Name)}}Model) TableName() string {
	return "{{.Service.Ast.Table.Name}}"
}
