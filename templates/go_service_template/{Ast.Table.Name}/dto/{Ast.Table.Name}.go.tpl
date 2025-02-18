package dto

import (
	"{{.Service.ProjectName | ToSnakeCase}}/{{.Service.Ast.Table.Name | ToSnakeCase}}/model"

	"github.com/fobus1289/ufa_shared/http/response" //
)

type Page{{.Service.Ast.Table.Name | ToUpperFirst}}ResponseType = response.PaginateResponse[*model.{{.Service.Ast.Table.Name | ToUpperFirst}}Model] // @name Page{{.Service.Ast.Table.Name | ToUpperFirst}}ResponseType

type Create{{.Service.Ast.Table.Name | ToUpperFirst}}Dto struct {
{{range $field := .Service.Ast.Table.Fields}}
	{{$field.Name | ToUpperFirst}} {{$field.Type | ToSnakeCase}} `json:"{{$field.Name | ToSnakeCase}}"`
{{end}}
} //@name Create{{.Service.Ast.Table.Name | ToUpperFirst}}Dto

type Update{{.Service.Ast.Table.Name | ToUpperFirst}}Dto struct {
{{range $field := .Service.Ast.Table.Fields}}
	{{$field.Name | ToUpperFirst}} *{{$field.Type | ToSnakeCase}} `json:"{{$field.Name | ToSnakeCase}}"`
{{end}}
} //@name Update{{.Service.Ast.Table.Name | ToUpperFirst}}Dto

{{range .Service.Ast.FindRoute}}
{{if gt (len .Queries) 0}}
type {{.Func | ToCamelCase | ToUpperFirst}}QueryDto struct {
    {{range $query := .Queries}}
    {{$query.Name | ToUpperFirst}} {{if not $query.Required}}*{{end}}{{$query.Type | ToSnakeCase}} `json:"{{$query.Name | ToSnakeCase}}"`
    {{end}}
} //@name {{.Func | ToCamelCase | ToUpperFirst}}QueryDto
{{end}}
{{end}}

{{range .Service.Ast.FindOneRoute}} //
{{if gt (len .Queries) 0}}
type {{.Func | ToCamelCase | ToUpperFirst}}QueryDto struct {
    {{range $query := .Queries}}
    {{$query.Name | ToUpperFirst}} {{if not $query.Required}}*{{end}}{{$query.Type | ToSnakeCase}} `json:"{{$query.Name | ToSnakeCase}}"`
    {{end}}
} //@name {{.Func | ToCamelCase | ToUpperFirst}}QueryDto
{{end}}
{{end}}