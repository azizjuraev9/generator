package service

import (
	"context"
	"math"
	"samplePath/{{Service}}/dto"
	"samplePath/{{Service}}/model"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type SampleService interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.SampleModel, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.SampleModel, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageSampleResponseType, error)
	Create(sampleDto *dto.CreateSampleDto) (*response.ID, error)
	Update(sampleDto *dto.UpdateSampleDto, scopes ...ServiceScope) error
	ChangeVisibility(scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type sampleService struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) SampleService {
	return &sampleService{db}
}

func (s *sampleService) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.SampleModel{})
}

func (s *sampleService) Model() *gorm.DB {
	return s.db.Model(&model.SampleModel{})
}

func (s *sampleService) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.SampleModel, error) {

	var sample model.SampleModel
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&sample).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &sample, nil
}

func (s *sampleService) Find(ctx context.Context, scopes ...ServiceScope) ([]model.SampleModel, error) {

	var moreModels []model.SampleModel
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

func (s *sampleService) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageSampleResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var samples []*model.SampleModel
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&samples).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, samples), nil
}

func (s *sampleService) Create(sampleDto *dto.CreateSampleDto) (*response.ID, error) {

	sample := model.SampleModel{
		Name: sampleDto.Name,
	}

	if err := s.db.Create(&sample).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: sample.Id}, nil
}

func (s *sampleService) Update(sampleDto *dto.UpdateSampleDto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates(sampleDto).Error
}

func (s *sampleService) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}

func (s *sampleService) ChangeVisibility(scopes ...ServiceScope) error {
	var sample model.SampleModel

	if err := s.Model().Scopes(scopes...).First(&sample).Error; err != nil {
		return err
	}

	newVisibility := !sample.IsVisible

	if err := s.Model().Scopes(scopes...).Updates(map[string]interface{}{"is_visible": newVisibility}).Error; err != nil {
		return err
	}

	return nil
}
