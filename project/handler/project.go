package handler

import (
	"errors"
	"fmt"
	"generator/project/dto"
	"generator/project/generator"
	_ "generator/project/model"
	"generator/project/service"
	"strconv"
	"strings"

	"github.com/fobus1289/ufa_shared/http"
	_ "github.com/fobus1289/ufa_shared/http/response"
	"github.com/fobus1289/ufa_shared/http/validator"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

type projectHandler struct {
	service service.ProjectService
}

func NewHandler(router *echo.Group, service service.ProjectService) {

	group := router.Group("/project")
	{
		handler := &projectHandler{service: service}

		group.POST("", handler.Create)
		group.GET("/page", handler.Page)
		group.GET("/:id", handler.GetById)
		group.GET("/search", handler.Search)
		group.PATCH("/:id", handler.Update)
		group.DELETE("/:id", handler.Delete)
		group.POST("/generate/:id", handler.Generate)

	}
}

// Generate godoc
// @Summary      GetContent project by ID
// @Description  GetContent project by ID
// @Tags 		 project
// @ID           generate-project
// @Accept       json
// @Produce      json
// @Param        id path string true "project ID"
// @Success      200 {object} model.ProjectModel "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project/{id} [get]
func (e *projectHandler) Generate(c echo.Context) error {

	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("error parse id")
			return http.HTTPError(err).BadRequest()
		}
	}

	ctx := c.Request().Context()

	filter := func(tx *gorm.DB) *gorm.DB {
		return tx.Where("id = ?", id).Preload("Services")
	}

	project, err := e.service.FindOne(ctx, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	generator.Generate("D:\\projects\\organisation_service\\templates\\go_service_template", "D:\\projects\\organisation_service\\generated\\"+project.Name, project.Services)

	return http.Response(c).OK(project)
}

// Create godoc
// @Summary      Create a new project
// @Description  Create project
// @Tags 		 project
// @ID           create-project
// @Accept       json
// @Produce      json
// @Param        input body dto.CreateProjectDto true "project information"
// @Success      201 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project [post]
func (e *projectHandler) Create(c echo.Context) error {
	var createDto dto.CreateProjectDto
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
// @Summary      GetContent all project with pagination
// @Description  GetContent all project with pagination
// @Tags 		 project
// @ID           get-all-project
// @Accept       json
// @Produce      json
// @Param        page query string false "Page number" default(1)
// @Param        perpage query string false "Number of items per page" default(10)
// @Param        search query string false "Searching by name or description"
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project/page [get]
func (e *projectHandler) Page(c echo.Context) error {
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
// @Summary      GetContent all project with pagination
// @Description  GetContent all project with pagination
// @Tags 		 project
// @ID           search-project
// @Accept       json
// @Produce      json
// @Param        search query string false "Searching by name or description"
// @Param        limit  query int    false "Limit the number of results" default(20)
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project/search [get]
func (e *projectHandler) Search(c echo.Context) error {
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
// @Summary      GetContent project by ID
// @Description  GetContent project by ID
// @Tags 		 project
// @ID           get-project-by-id
// @Accept       json
// @Produce      json
// @Param        id path string true "project ID"
// @Success      200 {object} model.ProjectModel "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project/{id} [get]
func (e *projectHandler) GetById(c echo.Context) error {

	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("error parse id")
			return http.HTTPError(err).BadRequest()
		}
	}

	ctx := c.Request().Context()

	filter := func(tx *gorm.DB) *gorm.DB {
		return tx.Where("id = ?", id).Preload("Services")
	}

	project, err := e.service.FindOne(ctx, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).OK(project)
}

// Update godoc
// @Summary      Update project information
// @Description  Update project information by ID
// @Tags 		 project
// @ID           update-project
// @Accept       json
// @Param        id path string true "project ID"
// @Param        input body dto.UpdateProjectDto true "project information"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project/{id} [patch]
func (e *projectHandler) Update(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	var updateDto dto.UpdateProjectDto
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
// @Summary      Delete project
// @Description  Delete project by ID
// @Tags 		 project
// @ID           delete-project
// @Accept       json
// @Param        id path string true "project ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /project/{id} [delete]
func (e *projectHandler) Delete(c echo.Context) error {
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
