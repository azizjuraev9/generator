package ast

type Ast struct {
	Table        CreateTableDto     `json:"table"`
	FindRoute    *[]FindRouteDto    `json:"find_route"`
	FindOneRoute *[]FindOneRouteDto `json:"find_one_route"`
	CreateRoute  *[]CreateRouteDto  `json:"create_route"`
	UpdateRoute  *[]UpdateRouteDto  `json:"update_route"`
	//Routes []Route // @type FindRouteDto
} //@name Ast

// ------------------------------------------------------------------------------

type CreateTableDto struct {
	Name   string  `json:"name"`
	Fields []Field `json:"fields"`
} //@name CreateTableDto

type Field struct {
	Name           string    `json:"name"`
	Type           string    `json:"type"`
	Relation       *Relation `json:"relation"`
	IsNull         bool      `json:"is_null"`
	Default        string    `json:"default"`
	IsTranslatable bool      `json:"is_translatable"`
} //@name Field

type Relation struct {
	Table     string `json:"table"`
	Type      string `json:"type"`
	RefTable  string `json:"ref_table"`
	RefColumn string `json:"ref_column"`
} //@name Relation

// ------------------------------------------------------------------------------

type Route interface {
	GetRoute() string
	GetFunc() string
	GetRole() *string
	GetPermission() *string
	GetMethod() string
	GetPath() []QueryParam
}

type BaseRoute struct {
	Route      string  `json:"route"`
	Func       string  `json:"func"`
	Role       *string `json:"role"`
	Permission *string `json:"permission"`
	Method     string  `json:"method"`
} //@name BaseRoute

type FindRouteDto struct {
	BaseRoute
	Path       []QueryParam `json:"path"`
	Queries    []QueryParam `json:"queries"`
	Headers    []QueryParam `json:"headers"`
	Response   Response     `json:"response"`
	Joins      []Join       `json:"joins"`
	Conditions []Condition  `json:"conditions"`
} //@name FindRouteDto

type FindOneRouteDto FindRouteDto //@name FindOneRouteDto

type CreateRouteDto struct {
	BaseRoute
} //@name CreateRouteDto

type UpdateRouteDto CreateRouteDto //@name UpdateRouteDto

type QueryParam struct {
	Name      string `json:"name"`
	Type      string `json:"type"`
	Validator string `json:"validator"`
	Required  bool   `json:"required"`
	Column    string `json:"column"`
	Op        string `json:"op"`
} //@name QueryParam

type Response struct {
	Fields   []string `json:"fields"`
	Preloads []string `json:"preloads"`
} //@name Response

type Join struct {
	Table     string    `json:"table"`
	Type      string    `json:"type"`
	Condition Condition `json:"condition"`
} //@name Join

type Condition struct {
	Column string `json:"column"`
	Op     string `json:"op"`
	Value  string `json:"value"`
} //@name Condition

// CreateRouteDto --------------------------------------------->
func (r CreateRouteDto) GetRoute() string {
	return r.Route
}

func (r CreateRouteDto) GetFunc() string {
	return r.Func
}

func (r CreateRouteDto) GetRole() *string {
	return r.Role
}

func (r CreateRouteDto) GetPermission() *string {
	return r.Permission
}

func (r CreateRouteDto) GetMethod() string {
	return r.Method
}

func (r CreateRouteDto) GetPath() []QueryParam {
	return []QueryParam{}
}

// UpdateRouteDto --------------------------------------------->
func (r UpdateRouteDto) GetRoute() string {
	return r.Route
}

func (r UpdateRouteDto) GetFunc() string {
	return r.Func
}

func (r UpdateRouteDto) GetRole() *string {
	return r.Role
}

func (r UpdateRouteDto) GetPermission() *string {
	return r.Permission
}

func (r UpdateRouteDto) GetMethod() string {
	return r.Method
}

func (r UpdateRouteDto) GetPath() []QueryParam {
	return []QueryParam{}
}

// FindRouteDto --------------------------------------------->
func (r FindRouteDto) GetRoute() string {
	return r.Route
}

func (r FindRouteDto) GetFunc() string {
	return r.Func
}

func (r FindRouteDto) GetRole() *string {
	return r.Role
}

func (r FindRouteDto) GetPermission() *string {
	return r.Permission
}

func (r FindRouteDto) GetMethod() string {
	return r.Method
}

func (r FindRouteDto) GetPath() []QueryParam {
	return r.Path
}

// FindOneRouteDto --------------------------------------------->
func (r FindOneRouteDto) GetRoute() string {
	return r.Route
}

func (r FindOneRouteDto) GetFunc() string {
	return r.Func
}

func (r FindOneRouteDto) GetRole() *string {
	return r.Role
}

func (r FindOneRouteDto) GetPermission() *string {
	return r.Permission
}

func (r FindOneRouteDto) GetMethod() string {
	return r.Method
}

func (r FindOneRouteDto) GetPath() []QueryParam {
	return r.Path
}
