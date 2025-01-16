package dto

import (
	"samplePath/{{Service}}/model"

	"github.com/fobus1289/ufa_shared/http/response"
)

type Page{{ToUpperFirst(.Table.Name)}}ResponseType = response.PaginateResponse[*model.{{ToUpperFirst(.Table.Name)}}Model] // @name Page{{ToUpperFirst(.Table.Name)}}ResponseType

type Create{{ToUpperFirst(.Table.Name)}}Dto struct {
{{range $field := .Ast.Table.Fields}}
	{{ToUpperFirst($field.Name)}} {{ToSnakeCase($field.Type)}} `json:"{{ToSnakeCase($field.Name)}}"`
{{end}}
} //@name Create{{ToUpperFirst(.Table.Name)}}Dto

type Update{{ToUpperFirst(.Table.Name)}}Dto struct {
{{range $field := .Ast.Table.Fields}}
	{{ToUpperFirst($field.Name)}} *{{ToSnakeCase($field.Type)}} `json:"{{ToSnakeCase($field.Name)}}"`
{{end}}
} //@name Update{{ToUpperFirst(.Table.Name)}}Dto
