package dto

import (
	"generator/organisation/model"

	"github.com/fobus1289/ufa_shared/http/response"
)

type PageOrganisationResponseType = response.PaginateResponse[*model.OrganisationModel] // @name PageOrganisationResponseType

type CreateOrganisationDto struct {
	Name string `json:"name"`
} //@name CreateOrganisationDto

type UpdateOrganisationDto struct {
	Name *string `json:"name"`
} //@name UpdateOrganisationDto
