package service

import (
	"context"
	"math"
	"{{toSnakeCase(.ProjectName)}}/{{toSnakeCase(.Service.Ast.Table.Name)}}/dto"
	"{{toSnakeCase(.ProjectName)}}/{{toSnakeCase(.Service.Ast.Table.Name)}}/model"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type {{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Service interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.Page{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}ResponseType, error)
	Create({{toSnakeCase(.Service.ProjectName)}}Dto *dto.Create{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Dto) (*response.ID, error)
	Update({{toSnakeCase(.Service.ProjectName)}}Dto *dto.Update{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Dto, scopes ...ServiceScope) error
	ChangeVisibility(scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type {{toSnakeCase(.Service.ProjectName)}}Service struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) {{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Service {
	return &{{toSnakeCase(.Service.ProjectName)}}Service{db}
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model{})
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) Model() *gorm.DB {
	return s.db.Model(&model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model{})
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model, error) {

	var {{toSnakeCase(.Service.ProjectName)}} model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&{{toSnakeCase(.Service.ProjectName)}}).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &{{toSnakeCase(.Service.ProjectName)}}, nil
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) Find(ctx context.Context, scopes ...ServiceScope) ([]model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model, error) {

	var moreModels []model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model
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

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.Page{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}ResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var {{toSnakeCase(.Service.ProjectName)}}s []*model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&{{toSnakeCase(.Service.ProjectName)}}s).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, {{toSnakeCase(.Service.ProjectName)}}s), nil
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) Create({{toSnakeCase(.Service.ProjectName)}}Dto *dto.Create{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Dto) (*response.ID, error) {

	{{toSnakeCase(.Service.ProjectName)}} := model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model{
		Name: {{toSnakeCase(.Service.ProjectName)}}Dto.Name,
	}

	if err := s.db.Create(&{{toSnakeCase(.Service.ProjectName)}}).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: {{toSnakeCase(.Service.ProjectName)}}.Id}, nil
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) Update({{toSnakeCase(.Service.ProjectName)}}Dto *dto.Update{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Dto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates({{toSnakeCase(.Service.ProjectName)}}Dto).Error
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}

func (s *{{toSnakeCase(.Service.ProjectName)}}Service) ChangeVisibility(scopes ...ServiceScope) error {
	var {{toSnakeCase(.Service.ProjectName)}} model.{{toCamelCase(toUpperFirstCase(.Service.ProjectName))}}Model

	if err := s.Model().Scopes(scopes...).First(&{{toSnakeCase(.Service.ProjectName)}}).Error; err != nil {
		return err
	}

	newVisibility := !{{toSnakeCase(.Service.ProjectName)}}.IsVisible

	if err := s.Model().Scopes(scopes...).Updates(map[string]interface{}{"is_visible": newVisibility}).Error; err != nil {
		return err
	}

	return nil
}
