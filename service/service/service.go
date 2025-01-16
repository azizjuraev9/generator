package service

import (
	"context"
	"generator/service/dto"
	"generator/service/model"
	"math"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type ServiceService interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.ServiceModel, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.ServiceModel, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageServiceResponseType, error)
	Create(serviceDto *dto.CreateServiceDto) (*response.ID, error)
	Update(serviceDto *dto.UpdateServiceDto, scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type serviceService struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) ServiceService {
	return &serviceService{db}
}

func (s *serviceService) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.ServiceModel{})
}

func (s *serviceService) Model() *gorm.DB {
	return s.db.Model(&model.ServiceModel{})
}

func (s *serviceService) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.ServiceModel, error) {

	var service model.ServiceModel
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&service).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &service, nil
}

func (s *serviceService) Find(ctx context.Context, scopes ...ServiceScope) ([]model.ServiceModel, error) {

	var moreModels []model.ServiceModel
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

func (s *serviceService) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageServiceResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var services []*model.ServiceModel
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&services).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, services), nil
}

func (s *serviceService) Create(serviceDto *dto.CreateServiceDto) (*response.ID, error) {

	service := model.ServiceModel{
		Name:         serviceDto.Name,
		ProjectId:    serviceDto.ProjectId,
		Description:  serviceDto.Description,
		Multilingual: serviceDto.Multilingual,
		Ast:          serviceDto.Ast,
	}

	if err := s.db.Create(&service).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: service.Id}, nil
}

func (s *serviceService) Update(serviceDto *dto.UpdateServiceDto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates(serviceDto).Error
}

func (s *serviceService) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}
