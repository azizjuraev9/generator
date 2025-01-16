package service

import (
	"context"
	"generator/project/dto"
	"generator/project/model"
	"math"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type ProjectService interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.ProjectModel, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.ProjectModel, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageProjectResponseType, error)
	Create(projectDto *dto.CreateProjectDto) (*response.ID, error)
	Update(projectDto *dto.UpdateProjectDto, scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type projectService struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) ProjectService {
	return &projectService{db}
}

func (s *projectService) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.ProjectModel{})
}

func (s *projectService) Model() *gorm.DB {
	return s.db.Model(&model.ProjectModel{})
}

func (s *projectService) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.ProjectModel, error) {

	var project model.ProjectModel
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&project).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &project, nil
}

func (s *projectService) Find(ctx context.Context, scopes ...ServiceScope) ([]model.ProjectModel, error) {

	var moreModels []model.ProjectModel
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

func (s *projectService) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageProjectResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var projects []*model.ProjectModel
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&projects).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, projects), nil
}

func (s *projectService) Create(projectDto *dto.CreateProjectDto) (*response.ID, error) {

	project := model.ProjectModel{
		Name:        projectDto.Name,
		UserId:      projectDto.UserId,
		Description: projectDto.Description,
	}

	if err := s.db.Create(&project).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: project.Id}, nil
}

func (s *projectService) Update(projectDto *dto.UpdateProjectDto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates(projectDto).Error
}

func (s *projectService) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}
