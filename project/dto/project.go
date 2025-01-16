package dto

import (
	"generator/project/model"

	"github.com/fobus1289/ufa_shared/http/response"
)

type PageProjectResponseType = response.PaginateResponse[*model.ProjectModel] // @name PageProjectResponseType

type CreateProjectDto struct {
	Name        string `json:"name"`
	UserId      int    `json:"userId"`
	Description string `json:"description"`
} //@name CreateProjectDto

type UpdateProjectDto struct {
	Name        *string `json:"name"`
	UserId      *int    `json:"userId"`
	Description *string `json:"description"`
} //@name UpdateProjectDto
