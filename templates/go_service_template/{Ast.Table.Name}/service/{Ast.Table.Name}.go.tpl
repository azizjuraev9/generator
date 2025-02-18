package service

import (
	"context"
	"math"
	"{{.Service.ProjectName | ToCamelCase}}/{{.Service.Ast.Table.Name | ToSnakeCase}}/dto"
	"{{.Service.ProjectName | ToCamelCase}}/{{.Service.Ast.Table.Name | ToSnakeCase}}/model"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type {{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Service interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.Page{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}ResponseType, error)
	Create({{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Dto *dto.Create{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto) (*response.ID, error)
	Update({{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Dto *dto.Update{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto, scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type {{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) {{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Service {
	return &{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service{db}
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model{})
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) Model() *gorm.DB {
	return s.db.Model(&model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model{})
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model, error) {

	var {{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}, nil
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) Find(ctx context.Context, scopes ...ServiceScope) ([]model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model, error) {

	var moreModels []model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			Find(&moreModels).
			Error

		if err != nil {
			return nil, err
		}
	}

	return moreModels, nil
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.Page{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}ResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var {{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}s []*model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}s).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, {{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}s), nil
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) Create({{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Dto *dto.Create{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto) (*response.ID, error) {

	{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}} := model.{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Model{
		Name: {{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Dto.Name,
	}

	if err := s.db.Create(&{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: {{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}.Id}, nil
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) Update({{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Dto *dto.Update{{.Service.Ast.Table.Name | ToCamelCase | ToUpperFirst}}Dto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates({{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Dto).Error
}

func (s *{{.Service.Ast.Table.Name | ToCamelCase | ToLowerFirst}}Service) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}
