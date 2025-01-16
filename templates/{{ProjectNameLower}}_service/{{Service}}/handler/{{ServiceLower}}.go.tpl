package handler

import (
	"errors"
	"fmt"
	"samplePath/{{Service}}/dto"
	_ "samplePath/{{Service}}/model"
	"samplePath/{{Service}}/service"
	"strconv"
	"strings"

	"github.com/fobus1289/ufa_shared/http"
	_ "github.com/fobus1289/ufa_shared/http/response"
	"github.com/fobus1289/ufa_shared/http/validator"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

type sampleHandler struct {
	service service.SampleService
}

func NewHandler(router *echo.Group, service service.SampleService) {

	group := router.Group("/sample")
	{
		handler := &sampleHandler{service: service}

		group.POST("", handler.Create)
		group.GET("/page", handler.Page)
		group.GET("/:id", handler.GetById)
		group.GET("/search", handler.Search)
		group.PATCH("/:id", handler.Update)
		group.PUT("/:id", handler.ChangeVisibility)
		group.DELETE("/:id", handler.Delete)

	}
}

// Create godoc
// @Summary      Create a new sample
// @Description  Create sample
// @Tags 		 sample
// @ID           create-sample
// @Accept       json
// @Produce      json
// @Param        input body dto.CreateSampleDto true "sample information"
// @Success      201 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample [post]
func (e *sampleHandler) Create(c echo.Context) error {
	var createDto dto.CreateSampleDto
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
// @Summary      GetContent all sample with pagination
// @Description  GetContent all sample with pagination
// @Tags 		 sample
// @ID           get-all-sample
// @Accept       json
// @Produce      json
// @Param        page query string false "Page number" default(1)
// @Param        perpage query string false "Number of items per page" default(10)
// @Param        search query string false "Searching by name or description"
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample/page [get]
func (e *sampleHandler) Page(c echo.Context) error {
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
// @Summary      GetContent all sample with pagination
// @Description  GetContent all sample with pagination
// @Tags 		 sample
// @ID           get-all-sample
// @Accept       json
// @Produce      json
// @Param        search query string false "Searching by name or description"
// @Param        limit  query int    false "Limit the number of results" default(20)
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample/search [get]
func (e *sampleHandler) Search(c echo.Context) error {
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
// @Summary      GetContent sample by ID
// @Description  GetContent sample by ID
// @Tags 		 sample
// @ID           get-sample-by-id
// @Accept       json
// @Produce      json
// @Param        id path string true "sample ID"
// @Success      200 {object} model.SampleModel "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample/{id} [get]
func (e *sampleHandler) GetById(c echo.Context) error {

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

	sample, err := e.service.FindOne(ctx, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).OK(sample)
}

// Update godoc
// @Summary      Update sample information
// @Description  Update sample information by ID
// @Tags 		 sample
// @ID           update-sample
// @Accept       json
// @Param        id path string true "sample ID"
// @Param        input body dto.UpdateSampleDto true "sample information"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample/{id} [patch]
func (e *sampleHandler) Update(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	var updateDto dto.UpdateSampleDto
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
// @Summary      Delete sample
// @Description  Delete sample by ID
// @Tags 		 sample
// @ID           delete-sample
// @Accept       json
// @Param        id path string true "sample ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample/{id} [delete]
func (e *sampleHandler) Delete(c echo.Context) error {
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

// PUT godoc
// @Summary      put sample
// @Description  put sample by ID
// @Tags 		 sample
// @ID           change-visibility-sample
// @Accept       json
// @Param        id path string true "sample ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /sample/{id} [put]
func (e *sampleHandler) ChangeVisibility(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	filter := func(tx *gorm.DB) *gorm.DB {
		return tx.Where("id", id)
	}

	err := e.service.ChangeVisibility(filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).NoContent()
}
