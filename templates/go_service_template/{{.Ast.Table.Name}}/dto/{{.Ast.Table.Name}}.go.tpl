package dto

import (
	"{{toSnakeCase(.ProjectName)}}/{{toSnakeCase(.Ast.Table.Name)}}/model"

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

{{range .Ast.FindRoute}}
{{if gt (len .Queries) 0}}
type {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto struct {
    {{range $query := .Queries}}
    {{ToUpperFirst($query.Name)}} {{if not $query.Required}}*{{end}}{{ToSnakeCase($query.Type)}} `json:"{{ToSnakeCase($query.Name)}}"`
    {{end}}
} //@name {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto
{{end}}
{{end}}

{{range .Ast.FindOneRouteDto}}
{{if gt (len .Queries) 0}}
type {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto struct {
    {{range $query := .Queries}}
    {{ToUpperFirst($query.Name)}} {{if not $query.Required}}*{{end}}{{ToSnakeCase($query.Type)}} `json:"{{ToSnakeCase($query.Name)}}"`
    {{end}}
} //@name {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto
{{end}}
{{end}}