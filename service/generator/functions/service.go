package functions

import (
	"strings"
	"unicode"
)

func ToUpper(s string) string {
	return strings.ToUpper(s)
}

func ToLower(s string) string {
	return strings.ToLower(s)
}

func ToTitle(s string) string {
	return strings.ToTitle(s)
}

func ToUpperFirst(s string) string {
	return strings.ToUpper(s[:1]) + s[1:]
}

func ToLowerFirst(s string) string {
	return strings.ToLower(s[:1]) + s[1:]
}

func ToCamelCase(str string) string {

	str = strings.TrimSpace(str)

	var result strings.Builder

	for i, r := range str {

		if i == 0 || i == len(str)-1 {
			result.WriteRune(unicode.ToLower(r))
			continue
		}

		switch {
		case i == 0 || i == len(str)-1:
			result.WriteRune(unicode.ToLower(r))
		case unicode.IsUpper(r):
			result.WriteRune('_')
			result.WriteRune(unicode.ToLower(r))
		case unicode.IsSpace(r):
			result.WriteRune(r)
		default:
			result.WriteRune(r)
		}

	}

	return result.String()
}

func ToSnakeCase(str string) string {
	var result strings.Builder

	for i, r := range str {

		switch {
		case i == 0 || i == len(str)-1:
			result.WriteRune(unicode.ToLower(r))
		case unicode.IsUpper(r):
			result.WriteRune('_')
			result.WriteRune(unicode.ToLower(r))
		case unicode.IsSpace(r):
			result.WriteRune(r)
		default:
			result.WriteRune(r)
		}

	}

	return result.String()
}

func GormAnnotations(params interface{}) string {

	var annotations []string

	// Primary key annotation
	if strings.ToLower(params.Name) == "id" {
		annotations = append(annotations, "primaryKey")
	}

	// Nullable annotation
	if params.IsNull {
		annotations = append(annotations, "null")
	} else {
		annotations = append(annotations, "not null")
	}

	// Default value annotation
	if params.Default != "" {
		annotations = append(annotations, "default:"+params.Default)
	}

	// Relation annotation
	if params.Relation != nil {
		switch params.Relation.Type {
		case "one-to-one":
			annotations = append(annotations, "foreignKey:"+params.Name+";references:"+params.Relation.RefColumn)
		case "one-to-many":
			annotations = append(annotations, "foreignKey:"+params.Name+";references:"+params.Relation.RefColumn)
		case "many-to-many":
			annotations = append(annotations, "many2many:"+params.Relation.RefTable)
		}
	}

	return strings.Join(annotations, ";")
}
