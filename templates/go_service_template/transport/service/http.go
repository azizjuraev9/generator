package service

import (
	sampleHandler "samplePath/{{Service}}/handler"
	sampleService "samplePath/{{Service}}/service"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

func NewService(routerGroup *echo.Group, db *gorm.DB) {
	sampleHandler.NewHandler(routerGroup, sampleService.NewService(db))
}
