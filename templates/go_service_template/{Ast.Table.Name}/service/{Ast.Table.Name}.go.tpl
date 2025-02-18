package service

import (
	"context"
	"math"
	"{{.Service.ProjectName | ToSnakeCase}}/{{.Service.Ast.Table.Name | ToSnakeCase}}/dto" //
	"{{.Service.ProjectName | ToSnakeCase}}/{{.Service.Ast.Table.Name | ToSnakeCase}}/model"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type {{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Service interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.Page{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}ResponseType, error)
	Create({{.Service.ProjectName | ToSnakeCase}}Dto *dto.Create{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Dto) (*response.ID, error)
	Update({{.Service.ProjectName | ToSnakeCase}}Dto *dto.Update{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Dto, scopes ...ServiceScope) error
	ChangeVisibility(scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type {{.Service.ProjectName | ToSnakeCase}}Service struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) {{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Service {
	return &{{.Service.ProjectName | ToSnakeCase}}Service{db}
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model{})
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) Model() *gorm.DB {
	return s.db.Model(&model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model{})
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model, error) {

	var {{.Service.ProjectName | ToSnakeCase}} model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&{{.Service.ProjectName | ToSnakeCase}}).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &{{.Service.ProjectName | ToSnakeCase}}, nil
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) Find(ctx context.Context, scopes ...ServiceScope) ([]model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model, error) {

	var moreModels []model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model
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

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.Page{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}ResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var {{.Service.ProjectName | ToSnakeCase}}s []*model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&{{.Service.ProjectName | ToSnakeCase}}s).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, {{.Service.ProjectName | ToSnakeCase}}s), nil
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) Create({{.Service.ProjectName | ToSnakeCase}}Dto *dto.Create{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Dto) (*response.ID, error) {

	{{.Service.ProjectName | ToSnakeCase}} := model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model{
		Name: {{.Service.ProjectName | ToSnakeCase}}Dto.Name,
	}

	if err := s.db.Create(&{{.Service.ProjectName | ToSnakeCase}}).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: {{.Service.ProjectName | ToSnakeCase}}.Id}, nil
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) Update({{.Service.ProjectName | ToSnakeCase}}Dto *dto.Update{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Dto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates({{.Service.ProjectName | ToSnakeCase}}Dto).Error
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}

func (s *{{.Service.ProjectName | ToSnakeCase}}Service) ChangeVisibility(scopes ...ServiceScope) error {
	var {{.Service.ProjectName | ToSnakeCase}} model.{{.Service.ProjectName | ToCamelCase | ToUpperFirst}}Model

	if err := s.Model().Scopes(scopes...).First(&{{.Service.ProjectName | ToSnakeCase}}).Error; err != nil {
		return err
	}

	newVisibility := !{{.Service.ProjectName | ToSnakeCase}}.IsVisible

	if err := s.Model().Scopes(scopes...).Updates(map[string]interface{}{"is_visible": newVisibility}).Error; err != nil {
		return err
	}

	return nil
}
