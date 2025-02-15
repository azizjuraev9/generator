package main

import (
	"log"
	"strconv"
    {{range .Services}}
	{{toLower .Ast.Table.Name}}Handler "{{toSnakeCase $.ProjectName}}/{{toLower .Ast.Table.Name}}/handler"
	{{toLower .Ast.Table.Name}}Model "{{toSnakeCase $.ProjectName}}/{{toLower .Ast.Table.Name}}/model"
	{{toLower .Ast.Table.Name}}Service "{{toSnakeCase $.ProjectName}}/{{toLower .Ast.Table.Name}}/service"
    {{end}}

	"gorm.io/gorm"

	loader "github.com/fobus1289/ufa_shared/config"
	"github.com/fobus1289/ufa_shared/pg"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {

	projectEnv := loader.ProjectEnv()

	pgConfig := pg.NewConfigEmpty()
	{
		pgConfig.SetHost(projectEnv.PgHost).
			SetPort(projectEnv.PgPort).
			SetDbname(projectEnv.PgDB).
			SetUser(projectEnv.PgUser).
			SetPassword(projectEnv.PgPassword)
	}

	db, err := pg.NewGorm(&pgConfig)
	{
		if err != nil {
			log.Panicln(err)
		}

		db.AutoMigrate(
            {{range .Services}}
			{{toLower .Ast.Table.Name}}Model.{{toUpperFirst .Ast.Table.Name}}Model{},
            {{end}}
		)
	}

	router := echo.New()
	{
		setMiddlewares(router)
		createHandlers(router, db)
		runHTTPServerOnAddr(router, projectEnv.HttpPort)
	}
}

func runHTTPServerOnAddr(handler *echo.Echo, port int) {
	url := strconv.FormatInt(int64(port), 10)
	{
		log.Panicln(handler.Start(":" + url))
	}
}

func setMiddlewares(router *echo.Echo) {
	router.Use(middleware.RemoveTrailingSlash())
	router.Use(middleware.RequestID())
	router.Use(middleware.Recover())
	router.Use(middleware.CORS())
}

func createHandlers(router *echo.Echo, db *gorm.DB) {
	group := router.Group("/api/v1")
	{
        {{range .Services}}
		{{toLower .Ast.Table.Name}}Handler.NewHandler(group, {{toLower .Ast.Table.Name}}Service.NewService(db))
        {{end}}
	}
}