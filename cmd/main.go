package main

import (
	organisationHandler "generator/organisation/handler"
	organisationModel "generator/organisation/model"
	organisationService "generator/organisation/service"
	"log"
	"strconv"

	"gorm.io/gorm"

	projectHandler "generator/project/handler"
	projectModel "generator/project/model"
	projectService "generator/project/service"
	serviceHandler "generator/service/handler"
	serviceModel "generator/service/model"
	serviceService "generator/service/service"
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
			organisationModel.OrganisationModel{},
			projectModel.ProjectModel{},
			serviceModel.ServiceModel{},
		)
	}

	router := echo.New()
	{
		setMiddlewares(router)
		createHandler(router, db)
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

func createHandler(router *echo.Echo, db *gorm.DB) {
	group := router.Group("/api/v1")
	{
		organisationHandler.NewHandler(group, organisationService.NewService(db))
		projectHandler.
			NewHandler(group, projectService.NewService(db))
		serviceHandler.
			NewHandler(group, serviceService.NewService(db))

	}
}
