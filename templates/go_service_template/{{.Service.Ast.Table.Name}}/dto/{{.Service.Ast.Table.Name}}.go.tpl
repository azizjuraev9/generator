package dto

import (
	"{{toSnakeCase(.Service.ProjectName)}}/{{toSnakeCase(.Service.Ast.Service.Table.Name)}}/model"

	"github.com/fobus1289/ufa_shared/http/response"
)

type Page{{ToUpperFirst(.Service.Table.Name)}}ResponseType = response.PaginateResponse[*model.{{ToUpperFirst(.Service.Table.Name)}}Model] // @name Page{{ToUpperFirst(.Service.Table.Name)}}ResponseType

type Create{{ToUpperFirst(.Service.Table.Name)}}Dto struct {
{{range $field := .Service.Ast.Service.Table.Fields}}
	{{ToUpperFirst($field.Name)}} {{ToSnakeCase($field.Type)}} `json:"{{ToSnakeCase($field.Name)}}"`
{{end}}
} //@name Create{{ToUpperFirst(.Service.Table.Name)}}Dto

type Update{{ToUpperFirst(.Service.Table.Name)}}Dto struct {
{{range $field := .Service.Ast.Service.Table.Fields}}
	{{ToUpperFirst($field.Name)}} *{{ToSnakeCase($field.Type)}} `json:"{{ToSnakeCase($field.Name)}}"`
{{end}}
} //@name Update{{ToUpperFirst(.Service.Table.Name)}}Dto

{{range .Service.Ast.FindRoute}}
{{if gt (len .Queries) 0}}
type {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto struct {
    {{range $query := .Queries}}
    {{ToUpperFirst($query.Name)}} {{if not $query.Required}}*{{end}}{{ToSnakeCase($query.Type)}} `json:"{{ToSnakeCase($query.Name)}}"`
    {{end}}
} //@name {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto
{{end}}
{{end}}

{{range .Service.Ast.FindOneRouteDto}}
{{if gt (len .Queries) 0}}
type {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto struct {
    {{range $query := .Queries}}
    {{ToUpperFirst($query.Name)}} {{if not $query.Required}}*{{end}}{{ToSnakeCase($query.Type)}} `json:"{{ToSnakeCase($query.Name)}}"`
    {{end}}
} //@name {{ToUpperFirst(ToCamelCase(.Func))}}QueryDto
{{end}}
{{end}}