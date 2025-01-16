package dto

import (
	"generator/service/ast"
	"generator/service/model"

	"github.com/fobus1289/ufa_shared/http/response"
)

type PageServiceResponseType = response.PaginateResponse[*model.ServiceModel] // @name PageServiceResponseType

type CreateServiceDto struct {
	Name         string  `json:"name"`
	ProjectId    int     `json:"projectId"`
	Description  string  `json:"description"`
	Multilingual bool    `json:"multilingual"`
	Ast          ast.Ast `json:"ast"`
} //@name CreateServiceDto

type UpdateServiceDto struct {
	Name         *string  `json:"name"`
	ProjectId    *int     `json:"projectId"`
	Description  *string  `json:"description"`
	Multilingual *bool    `json:"multilingual"`
	Ast          *ast.Ast `json:"ast"`
} //@name UpdateServiceDto

//----------------------------------------------------------------------------------------------------------------------
