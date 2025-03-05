package handler
{{$service := .Service}}

import (
	"errors"
	"fmt"
	"{{$service.ProjectName | ToCamelCase}}/{{$service.Ast.Table.Name | ToCamelCase}}/dto"
	_ "{{$service.ProjectName | ToCamelCase}}/{{$service.Ast.Table.Name | ToCamelCase}}/model"
	"{{$service.ProjectName | ToCamelCase}}/{{$service.Ast.Table.Name | ToCamelCase}}/service"

	"github.com/fobus1289/ufa_shared/http"
	_ "github.com/fobus1289/ufa_shared/http/response"
	"github.com/fobus1289/ufa_shared/http/validator"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

type {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler struct {
	service service.{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Service
}

func NewHandler(router *echo.Group, service service.{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Service) {

	group := router.Group("/{{$service.Ast.Table.Name | ToSnakeCase}}")
	{
		handler := &{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler{service: service}


        {{range $service.Ast.FindRoute}}group.{{.Method | ToUpper}}("{{.Route}}{{range .Path}}/:{{.Name}}{{end}}", handler.{{.Func | ToCamelCase | ToUpperFirst}}){{end}}
        {{range $service.Ast.FindOneRoute}}group.{{.Method | ToUpper}}("{{.Route}}{{range .Path}}/:{{.Name}}{{end}}", handler.{{.Func | ToCamelCase | ToUpperFirst}}){{end}}
        {{range $service.Ast.CreateRoute}}group.{{.Method | ToUpper}}("{{.Route}}", handler.{{.Func | ToCamelCase | ToUpperFirst}}){{end}}
        {{range $service.Ast.UpdateRoute}}group.{{.Method | ToUpper}}("{{.Route}}/:id", handler.{{.Func | ToCamelCase | ToUpperFirst}}){{end}}

	}
}

{{range $service.Ast.CreateRoute}}
// {{.Func | ToCamelCase | ToUpperFirst}} godoc
// @Summary      Create a new {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @Description  Create {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @Tags 		 {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @ID           {{.Func | ToCamelCase | ToUpperFirst}}
// @Accept       json
// @Produce      json
// @Param        input body dto.Create{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto true "{{$service.Ast.Table.Name | ToSnakeCase}} information"
// @Success      201 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}{{.Route}} [{{.Method | ToLower}}]
func (e *{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler) {{.Func | ToCamelCase | ToUpperFirst}}(c echo.Context) error {
	var createDto dto.Create{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto
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

{{range $service.Ast.FindRoute}}
// {{.Func | ToCamelCase | ToUpperFirst}} godoc
// @Summary      Find {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @Description  Find {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @Tags         {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @ID           {{.Func | ToCamelCase | ToUpperFirst}}
// @Accept       json
// @Produce      json
{{range .Queries}}// @Param        {{.Name}} query {{.Type}} {{if .Required}}true{{else}}false{{end}} "{{.Name}}"
{{end}}{{range .Path}}// @Param        {{.Name}} path {{.Type}} true "{{.Name}}"
{{end}}{{range .Headers}}// @Param        {{.Name}} header {{.Type}} true "{{.Name}}"
{{end}}// @Param        page query string false "Page number" default(1)
// @Param        perpage query string false "Number of items per page" default(10)
// @Success      200 {object} response.ID "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}{{.Route}}{{range .Path}}/{{"{"}}{{.Name}}{{"}"}}{{end}} [{{.Method | ToLower}}]
func (e *{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler) {{.Func | ToCamelCase | ToUpperFirst}}(c echo.Context) error {
	var ({{range .Path}}
	    path{{.Name | ToCamelCase | ToUpperFirst}} = c.Param("{{.Name}}"){{end}}{{range .Headers}}
	    header{{.Name | ToCamelCase | ToUpperFirst}} = c.Request().Header.Get("{{.Name}}"){{end}}
		page     = c.QueryParam("page")
		perPage  = c.QueryParam("perpage")
		paginate = http.NewPaginate(page, perPage)
		ctx      = c.Request().Context()
	)

	{{if gt (len .Queries) 0}}
	var queryDto dto.{{.Func | ToCamelCase | ToUpperFirst}}QueryDto
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
{{range .Joins}}tx = tx.Joins("{{.Type}} JOIN {{.Table}} ON {{.Condition.Column}} {{.Condition.Op}} {{.Condition.Value}}"){{end}}
        tx = tx.Select({{range .Response.Fields}}
            "{{.}}",{{end}}
        )
	    {{if gt (len .Queries) 0}}{{range $query := .Queries}}
	    if queryDto.{{$query.Name | ToUpperFirst}} != nil {
            {{if or (eq $query.Op "LIKE") (eq $query.Op "ILIKE")}}
            *queryDto.{{$query.Name | ToUpperFirst}} = fmt.Sprintf("%%%s%%", *queryDto.{{$query.Name | ToUpperFirst}})
            {{end}}
            tx = tx.Where("{{$query.Column | ToLowerFirst}} {{$query.Op}} ?", *queryDto.{{$query.Name | ToUpperFirst}})
	    }
	    {{end}}{{end}}
        {{range .Conditions}}tx = tx.Where("{{.Column}} {{.Op}} ?", {{ .Value | ResolveValue }}){{end}}
		return tx
	}

	{{range .Response.Preloads}}filter = filter.Preload("{{.}}"){{end}}

	pageData, err := e.service.Page(ctx, paginate.Take(), filter, limitFilter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}
	return http.Response(c).OK(pageData)
}
{{end}}

{{range $service.Ast.FindOneRoute}}
// GetById godoc
// @Summary      GetContent {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} by ID
// @Description  GetContent {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} by ID
// @Tags 		 {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @ID           {{.Func | ToCamelCase | ToUpperFirst}}
// @Accept       json
// @Produce      json
{{range .Queries}}// @Param        {{.Name}} query {{.Type}} {{if .Required}}true{{else}}false{{end}} "{{.Name}}"
{{end}}{{range .Path}}// @Param        {{.Name}} path {{.Type}} true "{{.Name}}"
{{end}}{{range .Headers}}// @Param        {{.Name}} header {{.Type}} true "{{.Name}}"
{{end}}// @Param        id path string true "{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} ID"
// @Success      200 {object} model.{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}{{.Route}}{{range .Path}}/{{"{"}}{{.Name}}{{"}"}}{{end}} [{{.Method | ToLower}}]
func (e *{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler) {{.Func | ToCamelCase | ToUpperFirst}}(c echo.Context) error {

    {{if gt (len .Queries) 0}}
    var queryDto dto.{{.Func | ToCamelCase | ToUpperFirst}}QueryDto
    {
        if err := c.Bind(&queryDto); err != nil {
            return http.HTTPError(err).BadRequest()
        }
    }
    {{end}}

    {{range .Path}}
    path{{.Name | ToCamelCase | ToUpperFirst}} := c.Param("{{.Name}}")
    {{end}}
    {{range .Headers}}
    header{{.Name | ToCamelCase | ToUpperFirst}} := c.Request().Header.Get("{{.Name}}")
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
        if queryDto.{{$query.Name | ToUpperFirst}} != nil {
            {{if or (eq $query.Op "LIKE") (eq $query.Op "ILIKE")}}
            *queryDto.{{$query.Name | ToUpperFirst}} = fmt.Sprintf("%%%s%%", *queryDto.{{$query.Name | ToUpperFirst}})
            {{end}}
            tx = tx.Where("{{$query.Column | ToLowerFirst}} {{$query.Op}} ?", *queryDto.{{$query.Name | ToUpperFirst}})
        }
        {{end}}
        {{end}}

        {{range .Conditions}}
        tx = tx.Where("{{.Column}} {{.Op}} ?", {{ .Value | ResolveValue }})
        {{end}}

        return tx
	}

	{{range .Response.Preloads}}
    filter = filter.Preload("{{.}}")
    {{end}}

	{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}, err := e.service.FindOne(ctx, filter)
	{
		if err != nil {
			return http.HTTPError(err).BadRequest()
		}
	}

	return http.Response(c).OK({{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}})
}
{{end}}

{{range $service.Ast.UpdateRoute}}
// Update godoc
// @Summary      Update {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} information
// @Description  Update {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} information by ID
// @Tags 		 {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @ID           {{.Func | ToCamelCase | ToUpperFirst}}
// @Accept       json
// @Param        id path string true "{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} ID"
// @Param        input body dto.Update{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto true "{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} information"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}/{id} [patch]
func (e *{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler) {{.Func | ToCamelCase | ToUpperFirst}}(c echo.Context) error {
	var id int64
	{
		if !http.PathValue(c.Param("id")).TryInt64(&id) {
			err := errors.New("parse id error")
			return http.HTTPError(err).BadRequest()
		}
	}

	var updateDto dto.Update{{$service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto
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
{{end}}

// Delete godoc
// @Summary      Delete {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @Description  Delete {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} by ID
// @Tags 		 {{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @ID           delete-{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}
// @Accept       json
// @Param        id path string true "{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} ID"
// @Success      204 "Successful operation"
// @Failure      400 {object} response.ErrorResponse "Bad request"
// @Failure      500 {object} response.ErrorResponse "Internal server error"
// @Router       /{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}/{id} [delete]
func (e *{{$service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Handler) Delete(c echo.Context) error {
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
