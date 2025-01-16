package service

import (
	organisationHandler "generator/organisation/handler"
	organisationService "generator/organisation/service"

	projectHandler "generator/project/handler"
	projectService "generator/project/service"
	serviceHandler "generator/service/handler"
	serviceService "generator/service/service"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

func NewService(routerGroup *echo.Group, db *gorm.DB) {
	organisationHandler.NewHandler(routerGroup, organisationService.NewService(db))
	projectHandler.NewHandler(
		routerGroup, projectService.NewService(db))
	serviceHandler.NewHandler(
		routerGroup, serviceService.NewService(db))

}
