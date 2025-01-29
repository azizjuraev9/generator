package handler

import (
	"errors"
	"fmt"
	"{{toSnakeCase(.ProjectName)}}/{{toSnakeCase(.Ast.Table.Name)}}/dto"
	_ "{{toSnakeCase(.ProjectName)}}/{{toSnakeCase(.Ast.Table.Name)}}/model"
	"{{toSnakeCase(.ProjectName)}}/{{toSnakeCase(.Ast.Table.Name)}}/service"
	"strconv"
	"strings"

	"github.com/fobus1289/ufa_shared/http"
	_ "github.com/fobus1289/ufa_shared/http/response"
	"github.com/fobus1289/ufa_shared/http/validator"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

type {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler struct {
	service service.{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Service
}

func NewHandler(router *echo.Group, service service.{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Service) {

	group := router.Group("/{{toSnakeCase(.Ast.Table.Name)}}")
	{
		handler := &{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler{service: service}


    {{range .Ast.FindRouteDto}}
	    group.{{ToUpper(.Method)}}("{{.Route}}{{range .Path}}/:{{.Name}}{{end}}", handler.{{ToUpperFirst(toCamelCase(.Func))}})
	{{end}}{{range .Ast.FindOneRouteDto}}
        group.{{ToLower(.Method)}}("{{.Route}}{{range .Path}}/:{{.Name}}{{end}}", handler.{{ToUpperFirst(toCamelCase(.Func))}})
    {{end}}{{range .Ast.CreateRouteDto}}
        group.{{ToLower(.Method)}}("{{.Route}}", handler.{{ToUpperFirst(toCamelCase(.Func))}})
    {{end}}{{range .Ast.UpdateRouteDto}}
        group.{{ToLower(.Method)}}("{{.Route}}/:id", handler.{{ToUpperFirst(toCamelCase(.Func))}})
    {{end}}

	}
}


{{range .Ast.CreateRouteDto}}
// {{ToUpperFirst(toCamelCase(.Func)}} godoc
// @Summary      Create a new {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Description  Create {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Tags 		 {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @ID           {{ToUpperFirst(toCamelCase(.Func)}}
// @Accept       json
// @Produce      json
// @Param        input body dto.Create{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Dto true "{{toSnakeCase(.Ast.Table.Name)}} information"
// @Success      201 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{toSnakeCase(.Ast.Table.Name)}} [post]
func (e *{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler) {{ToUpperFirst(toCamelCase(.Func)}}(c echo.Context) error {
	var createDto dto.Create{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Dto
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
{{end}}

{{range .Ast.FindRoute}}
// {{ToUpperFirst(ToCamelCase(.Func))}} godoc
// @Summary      {{.Description}}
// @Description  {{.Description}}
// @Tags         {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @ID           {{ToUpperFirst(ToCamelCase(.Func))}}
// @Accept       json
// @Produce      json
{{range .Queries}}
// @Param        {{.Name}} query {{.Type}} {{if .Required}}true{{else}}false{{end}} "{{.Description}}"
{{end}}
{{range .Path}}
// @Param        {{.Name}} path {{.Type}} true "{{.Description}}"
{{end}}
{{range .Headers}}
// @Param        {{.Name}} header {{.Type}} true "{{.Description}}"
{{end}}
// @Param        page query string false "Page number" default(1)
// @Param        perpage query string false "Number of items per page" default(10)
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}{{.Route}}{{range .Path}}/{{"{"}}{{.Name}}{{"}"}}{{end}} [{{ToLower(.Method)}}]
func (e *{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler) {{ToUpperFirst(toCamelCase(.Func)}}(c echo.Context) error {
	var (
	    {{range .Path}}
        path{{ToUpperFirst(ToCamelCase(.Name))}} = c.Param("{{.Name}}")
        {{end}}
        {{range .Headers}}
        header{{ToUpperFirst(ToCamelCase(.Name))}} = c.Request().Header.Get("{{.Name}}")
        {{end}}
		page     = c.QueryParam("page")
		perPage  = c.QueryParam("perpage")
		paginate = http.NewPaginate(page, perPage)
		ctx      = c.Request().Context()
	)

	{{if gt (len .Queries) 0}}
	var queryDto dto.{{ToUpperFirst(ToCamelCase(.Func))}}QueryDto
    {
        if err := c.Bind(&queryDto); err != nil {
            return http.HTTPError(err).BadRequest()
        }
    }
	{{end}}

	limitFilter := func(tx *gorm.DB) *gorm.DB {
		return tx.Offset(paginate.Skip()).Limit(paginate.Take()).Order("id ASC")
	}

	filter := func(tx *gorm.DB) *gorm.DB {

        {{range .Joins}}
        tx = tx.Joins("{{.Type}} JOIN {{.Table}} ON {{.Condition.Column}} {{.Condition.Op}} {{.Condition.Value}}")
        {{end}}

        tx = tx.Select(
            {{range .Response.Fields}}
            "{{.}}",
            {{end}}
        )

	    {{if gt (len .Queries) 0}}
	    {{range $query := .Queries}}
	    if queryDto.{{ToUpperFirst($query.Name)}} != nil {
            {{if $query.Op == "LIKE" || $query.Op == "ILIKE"}}
            *queryDto.{{ToUpperFirst($query.Name)}} = fmt.Sprintf("%%%s%%", *queryDto.{{ToUpperFirst($query.Name)}})
            {{end}}
            tx = tx.Where("{{ToLowerFirst($query.Column)}} {{$query.Op}} ?", *queryDto.{{ToUpperFirst($query.Name)}})
	    }
	    {{end}}
	    {{end}}

        {{range .Conditions}}
		tx = tx.Where("{{.Column}} {{.Op}} ?", {{ ResolveValue(.Value) }})
		{{end}}


		return tx
	}

	{{range .Response.Preloads}}
    filter = filter.Preload("{{.}}")
    {{end}}

	pageData, err := e.service.Page(ctx, paginate.Take(), filter, limitFilter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}
	return http.Response(c).OK(pageData)
}
{{end}}

{{range .Ast.FindOneRouteDto}}
// GetById godoc
// @Summary      GetContent {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} by ID
// @Description  GetContent {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} by ID
// @Tags 		 {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @ID           {{ToUpperFirst(ToCamelCase(.Func))}}
// @Accept       json
// @Produce      json
{{range .Queries}}
// @Param        {{.Name}} query {{.Type}} {{if .Required}}true{{else}}false{{end}} "{{.Description}}"
{{end}}
{{range .Path}}
// @Param        {{.Name}} path {{.Type}} true "{{.Description}}"
{{end}}
{{range .Headers}}
// @Param        {{.Name}} header {{.Type}} true "{{.Description}}"
{{end}}
// @Param        id path string true "{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} ID"
// @Success      200 {object} model.{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Model "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}{{.Route}}{{range .Path}}/{{"{"}}{{.Name}}{{"}"}}{{end}} [{{ToLower(.Method)}}]
func (e *{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler) GetById(c echo.Context) error {

    {{if gt (len .Queries) 0}}
    var queryDto dto.{{ToUpperFirst(ToCamelCase(.Func))}}QueryDto
    {
        if err := c.Bind(&queryDto); err != nil {
            return http.HTTPError(err).BadRequest()
        }
    }
    {{end}}

    {{range .Path}}
    path{{ToUpperFirst(ToCamelCase(.Name))}} := c.Param("{{.Name}}")
    {{end}}
    {{range .Headers}}
    header{{ToUpperFirst(ToCamelCase(.Name))}} := c.Request().Header.Get("{{.Name}}")
    {{end}}
	ctx := c.Request().Context()

	filter := func(tx *gorm.DB) *gorm.DB {

		{{range .Joins}}
        tx = tx.Joins("{{.Type}} JOIN {{.Table}} ON {{.Condition.Column}} {{.Condition.Op}} {{.Condition.Value}}")
        {{end}}

        tx = tx.Select(
            {{range .Response.Fields}}
            "{{.}}",
            {{end}}
        )

        {{if gt (len .Queries) 0}}
        {{range $query := .Queries}}
        if queryDto.{{ToUpperFirst($query.Name)}} != nil {
            {{if $query.Op == "LIKE" || $query.Op == "ILIKE"}}
            *queryDto.{{ToUpperFirst($query.Name)}} = fmt.Sprintf("%%%s%%", *queryDto.{{ToUpperFirst($query.Name)}})
            {{end}}
            tx = tx.Where("{{ToLowerFirst($query.Column)}} {{$query.Op}} ?", *queryDto.{{ToUpperFirst($query.Name)}})
        }
        {{end}}
        {{end}}

        {{range .Conditions}}
        tx = tx.Where("{{.Column}} {{.Op}} ?", {{ ResolveValue(.Value) }})
        {{end}}

        return tx
	}

	{{range .Response.Preloads}}
    filter = filter.Preload("{{.}}")
    {{end}}

	{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}, err := e.service.FindOne(ctx, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).OK({{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}})
}
{{end}}

// Update godoc
// @Summary      Update {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} information
// @Description  Update {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} information by ID
// @Tags 		 {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @ID           update-{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Accept       json
// @Param        id path string true "{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} ID"
// @Param        input body dto.Update{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Dto true "{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} information"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}/{id} [patch]
func (e *{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler) Update(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	var updateDto dto.Update{{ToUpperFirst(ToCamelCase(.Ast.Table.Name))}}Dto
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
// @Summary      Delete {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Description  Delete {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} by ID
// @Tags 		 {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @ID           delete-{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Accept       json
// @Param        id path string true "{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}/{id} [delete]
func (e *{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler) Delete(c echo.Context) error {
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
// @Summary      put {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Description  put {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} by ID
// @Tags 		 {{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @ID           change-visibility-{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}
// @Accept       json
// @Param        id path string true "{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}} ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}/{id} [put]
func (e *{{ToLowerFirst(ToCamelCase(.Ast.Table.Name))}}Handler) ChangeVisibility(c echo.Context) error {
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
