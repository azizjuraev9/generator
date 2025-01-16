package service

import (
	"context"
	"generator/organisation/dto"
	"generator/organisation/model"
	"math"

	"github.com/fobus1289/ufa_shared/http/response"
	"gorm.io/gorm"
)

type ServiceScope = func(d *gorm.DB) *gorm.DB

type OrganisationService interface {
	FindOne(ctx context.Context, scopes ...ServiceScope) (*model.OrganisationModel, error)
	Find(ctx context.Context, scopes ...ServiceScope) ([]model.OrganisationModel, error)
	Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageOrganisationResponseType, error)
	Create(organisationDto *dto.CreateOrganisationDto) (*response.ID, error)
	Update(organisationDto *dto.UpdateOrganisationDto, scopes ...ServiceScope) error
	Delete(scopes ...ServiceScope) error
}

type organisationService struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) OrganisationService {
	return &organisationService{db}
}

func (s *organisationService) ModelWithContext(ctx context.Context) *gorm.DB {
	return s.db.WithContext(ctx).Model(&model.OrganisationModel{})
}

func (s *organisationService) Model() *gorm.DB {
	return s.db.Model(&model.OrganisationModel{})
}

func (s *organisationService) FindOne(ctx context.Context, scopes ...ServiceScope) (*model.OrganisationModel, error) {

	var organisation model.OrganisationModel
	{
		err := s.ModelWithContext(ctx).
			Scopes(scopes...).
			First(&organisation).
			Error

		if err != nil {
			return nil, err
		}
	}

	return &organisation, nil
}

func (s *organisationService) Find(ctx context.Context, scopes ...ServiceScope) ([]model.OrganisationModel, error) {

	var moreModels []model.OrganisationModel
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

func (s *organisationService) Page(ctx context.Context, take int, filter, limitFilter ServiceScope) (*dto.PageOrganisationResponseType, error) {

	tx := s.ModelWithContext(ctx)

	var total int64
	{
		txTotal := tx.Scopes(filter).Count(&total)
		if err := txTotal.Error; err != nil {
			return nil, err
		}
	}

	var organisations []*model.OrganisationModel
	{
		if err := tx.Scopes(filter, limitFilter).
			Find(&organisations).Error; err != nil {
			return nil, err
		}
	}

	totalPages := int64(math.Ceil(float64(total) / float64(take)))

	return response.NewPaginateResponse(totalPages, organisations), nil
}

func (s *organisationService) Create(organisationDto *dto.CreateOrganisationDto) (*response.ID, error) {

	organisation := model.OrganisationModel{
		Name: organisationDto.Name,
	}

	if err := s.db.Create(&organisation).Error; err != nil {
		return nil, err
	}

	return &response.ID{Id: organisation.Id}, nil
}

func (s *organisationService) Update(organisationDto *dto.UpdateOrganisationDto, scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Updates(organisationDto).Error
}

func (s *organisationService) Delete(scopes ...ServiceScope) error {
	return s.Model().Scopes(scopes...).Delete(nil).Error
}
