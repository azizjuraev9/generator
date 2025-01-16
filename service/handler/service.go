package handler

import (
	"errors"
	"fmt"
	"generator/service/dto"
	_ "generator/service/model"
	"generator/service/service"
	"strconv"
	"strings"

	"github.com/fobus1289/ufa_shared/http"
	_ "github.com/fobus1289/ufa_shared/http/response"
	"github.com/fobus1289/ufa_shared/http/validator"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

type serviceHandler struct {
	service service.ServiceService
}

func NewHandler(router *echo.Group, service service.ServiceService) {

	group := router.Group("/service")
	{
		handler := &serviceHandler{service: service}

		group.POST("", handler.Create)
		group.GET("/page", handler.Page)
		group.GET("/:id", handler.GetById)
		group.GET("/search", handler.Search)
		group.PATCH("/:id", handler.Update)
		group.DELETE("/:id", handler.Delete)

	}
}

// Create godoc
// @Summary      Create a new service
// @Description  Create service
// @Tags 		 service
// @ID           create-service
// @Accept       json
// @Produce      json
// @Param        input body dto.CreateServiceDto true "service information"
// @Success      201 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /service [post]
func (e *serviceHandler) Create(c echo.Context) error {
	var createDto dto.CreateServiceDto
	{
		if err := c.Bind(&createDto); err != nil {
			return http.HTTPError(err).BadRequest()
		}

		if err := validator.Validate(createDto); err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	idDto, err := e.service.Create(&createDto)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).Created(idDto)
}

// Page godoc
// @Summary      GetContent all service with pagination
// @Description  GetContent all service with pagination
// @Tags 		 service
// @ID           get-all-service
// @Accept       json
// @Produce      json
// @Param        page query string false "Page number" default(1)
// @Param        perpage query string false "Number of items per page" default(10)
// @Param        search query string false "Searching by name or description"
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /service/page [get]
func (e *serviceHandler) Page(c echo.Context) error {
	var (
		search   = c.QueryParam("search")
		page     = c.QueryParam("page")
		perPage  = c.QueryParam("perpage")
		paginate = http.NewPaginate(page, perPage)
		ctx      = c.Request().Context()
	)

	limitFilter := func(tx *gorm.DB) *gorm.DB {
		return tx.Offset(paginate.Skip()).Limit(paginate.Take()).Order("id ASC")
	}

	filter := func(tx *gorm.DB) *gorm.DB {
		tx = tx.Where("is_visible = ?", true)

		if search != "" {
			search = fmt.Sprintf("%%%s%%", search)
			tx = tx.Where("name ILIKE ?", search)
		}
		return tx
	}

	pageData, err := e.service.Page(ctx, paginate.Take(), filter, limitFilter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}
	return http.Response(c).OK(pageData)
}

// Search godoc
// @Summary      GetContent all service with pagination
// @Description  GetContent all service with pagination
// @Tags 		 service
// @ID           search-service
// @Accept       json
// @Produce      json
// @Param        search query string false "Searching by name or description"
// @Param        limit  query int    false "Limit the number of results" default(20)
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /service/search [get]
func (e *serviceHandler) Search(c echo.Context) error {
	const defaultLimit = 15
	const maxLimit = 100

	search := strings.TrimSpace(c.QueryParam("search"))
	ctx := c.Request().Context()

	limitParam := c.QueryParam("limit")
	limit, err := strconv.Atoi(limitParam)
	{
		if err != nil || limit <= 0 {
			limit = defaultLimit
		}
		if limit > maxLimit {
			limit = maxLimit
		}
	}

	filter := func(tx *gorm.DB) *gorm.DB {
		tx = tx.Where("is_visible = ?", true)

		if search != "" {
			searchTerm := fmt.Sprintf("%%%s%%", search)
			tx = tx.Where("name ILIKE ?", searchTerm)
		}
		return tx.Limit(limit)
	}

	searchData, err := e.service.Find(ctx, filter)
	if err != nil {
		return http.HTTPError(err).BadRequest()
	}

	return http.Response(c).OK(searchData)
}

// GetById godoc
// @Summary      GetContent service by ID
// @Description  GetContent service by ID
// @Tags 		 service
// @ID           get-service-by-id
// @Accept       json
// @Produce      json
// @Param        id path string true "service ID"
// @Success      200 {object} model.ServiceModel "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /service/{id} [get]
func (e *serviceHandler) GetById(c echo.Context) error {

	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("error parse id")
			return http.HTTPError(err).BadRequest()
		}
	}

	ctx := c.Request().Context()

	filter := func(tx *gorm.DB) *gorm.DB {
		return tx.Where("id = ?", id).Where("is_visible = ?", true)
	}

	service, err := e.service.FindOne(ctx, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).OK(service)
}

// Update godoc
// @Summary      Update service information
// @Description  Update service information by ID
// @Tags 		 service
// @ID           update-service
// @Accept       json
// @Param        id path string true "service ID"
// @Param        input body dto.UpdateServiceDto true "service information"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /service/{id} [patch]
func (e *serviceHandler) Update(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	var updateDto dto.UpdateServiceDto
	{
		if err := c.Bind(&updateDto); err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	filter := func(tx *gorm.DB) *gorm.DB {
		return tx.Where("id", id)
	}

	err := e.service.Update(&updateDto, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).NoContent()
}

// Delete godoc
// @Summary      Delete service
// @Description  Delete service by ID
// @Tags 		 service
// @ID           delete-service
// @Accept       json
// @Param        id path string true "service ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /service/{id} [delete]
func (e *serviceHandler) Delete(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	{
		filter := func(tx *gorm.DB) *gorm.DB {
			return tx.Where("id", id)
		}

		if err := e.service.Delete(filter); err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).NoContent()
}
