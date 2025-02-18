package model
{{$service := .Service}}

import (
	"time"
    {{range $service.Ast.Table.Fields}}
    {{if .Relation}}
    {{ .Relation.RefTable | ToCamelCase | ToLowerFirst}}Model "{{$service.ProjectName | ToSnakeCase}}/{{$service.Ast.Table.Name | ToSnakeCase}}/{{ .Relation.RefTable | ToSnakeCase}}/model"
    {{end}}
    {{end}}
	"gorm.io/gorm"
)

type {{$service.Ast.Table.Name | ToUpperFirst}}Model struct {
	Id        int64           `json:"id" gorm:"primaryKey"`
    {{$service.Ast.Table.Fields | GormFields}}
	CreatedAt *time.Time      `json:"createdAt" gorm:"autoCreateTime:true"`
	UpdatedAt *time.Time      `json:"updatedAt,omitempty" gorm:"autoUpdateTime:true"`
	DeletedAt *gorm.DeletedAt `json:"-" swaggerignore:"true"`
}

func ({{$service.Ast.Table.Name | ToUpperFirst}}Model) TableName() string {
	return "{{$service.Ast.Table.Name}}"
}
