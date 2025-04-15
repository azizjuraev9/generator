package service

import (
    {{range .Services}}
	{{.Ast.Table.Name | ToLower}}Handler "{{.ProjectName | ToCamelCase}}/{{.Ast.Table.Name | ToLower}}/handler"
	{{.Ast.Table.Name | ToLower}}Service "{{.ProjectName | ToCamelCase}}/{{.Ast.Table.Name | ToLower}}/service"
    {{end}}
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

func NewService(routerGroup *echo.Group, db *gorm.DB) {
    {{range .Services}}
	{{.Ast.Table.Name | ToLower}}Handler.NewHandler(routerGroup, {{.Ast.Table.Name | ToLower}}Service.NewService(db))
    {{end}}
}
