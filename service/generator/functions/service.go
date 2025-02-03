package functions

import (
	"fmt"
	"strconv"
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

	// Default value annotation
	if params.Default != "" {
		annotations = append(annotations, "default:"+params.Default)
	}

	return strings.Join(annotations, ";")
}

func GormFields(fields []interface{}) string {
	var gormFields []string
	for _, field := range fields {
		var gormField = "\t"

		gormField += ToUpperFirst(ToCamelCase(field.Name)) + "\t"
		if field.IsNull {
			gormField += "*"
		}
		gormField += ToLower(field.Type)
		gormField += "\t`json:\"" + ToSnakeCase(field.Name) + "\" gorm:\"" + GormAnnotations(field) + "\"`"
		if field.Relation != nil {
			gormField += "\n\t"

			if field.Relation != nil && (field.Relation.Type == "one-to-many" || field.Relation.Type == "many-to-many") {
				gormField += "[]"
			}

			gormField += ToUpperFirst(field.Relation.Table) + "\t"

			if field.IsNull {
				gormField += "*"
			}

			gormField += ToLowerFirst(field.Relation.Table) + "Model." + ToUpperFirst(field.Relation.Table) + "Model\t"
			gormField += "\t`json:\"" + ToSnakeCase(field.Relation.Table) + "\""
			if field.Relation != nil {
				switch field.Relation.Type {
				case "one-to-one":
					gormField += "foreignKey:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn)) + ";references:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn))
				case "one-to-many":
					gormField += "foreignKey:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn)) + ";references:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn))
				case "many-to-one":
					gormField += "foreignKey:" + ToUpperFirst(ToCamelCase(field.Name))
				case "many-to-many":
					gormField += "many2many:" + ToSnakeCase(field.Relation.RefTable)
				}
			}
			gormField += "`"
		}
		gormFields = append(gormFields, gormField)
	}
	return strings.Join(gormFields, "\n")
}

func ResolveValue(value string) interface{} {
	switch {
	case value == "bool.true":
		return true
	case value == "bool.false":
		return false
	case strings.HasPrefix(value, "path."):
		return "path" + ToUpperFirst(ToCamelCase(strings.TrimPrefix(value, "path.")))
	case strings.HasPrefix(value, "header."):
		return "header" + ToUpperFirst(ToCamelCase(strings.TrimPrefix(value, "header.")))
	case strings.HasPrefix(value, "int."):
		// Преобразуем строку в int
		intValue, err := strconv.Atoi(strings.TrimPrefix(value, "int."))
		if err != nil {
			panic(fmt.Sprintf("invalid integer value: %s", value))
		}
		return intValue
	case strings.HasPrefix(value, "string."):
		// Оборачиваем строку в кавычки
		return fmt.Sprintf("\"%s\"", strings.TrimPrefix(value, "string."))
	default:
		// По умолчанию возвращаем исходное значение
		return value
	}
}
