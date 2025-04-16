package functions

import (
	"fmt"
	"generator/service/ast"
	"regexp"
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
	if len(s) == 0 {
		return s
	}

	return strings.ToUpper(s[:1]) + s[1:]
}

func ToLowerFirst(s string) string {
	if len(s) == 0 {
		return s
	}
	return strings.ToLower(s[:1]) + s[1:]
}

func ToCamelCase(input string) string {
	words := strings.FieldsFunc(input, func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})

	for i := range words {
		words[i] = strings.Title(strings.ToLower(words[i]))
	}

	return strings.Join(words, "")
}

func ToSnakeCase(input string) string {
	var result []rune

	for i, r := range input {
		if unicode.IsUpper(r) {
			// Если это не первый символ и предыдущий не был разделителем, добавляем "_"
			if i > 0 && (unicode.IsLower(rune(input[i-1])) || unicode.IsDigit(rune(input[i-1]))) {
				result = append(result, '_')
			}
			result = append(result, unicode.ToLower(r))
		} else if unicode.IsSpace(r) || r == '-' || r == '.' {
			// Пробелы и дефисы заменяем на "_"
			result = append(result, '_')
		} else {
			result = append(result, r)
		}
	}

	// Убираем возможные лишние символы
	snake := string(result)
	snake = strings.ToLower(snake)
	snake = regexp.MustCompile(`_+`).ReplaceAllString(snake, "_") // Убираем двойные "__"
	return strings.Trim(snake, "_")                               // Убираем возможные "_" в начале/конце строки
}

func GormAnnotations(params ast.Field) string {

	var annotations []string

	// Default value annotation
	if params.Default != "" {
		annotations = append(annotations, "default:"+params.Default)
	}

	return strings.Join(annotations, ";")
}

func GormFields(fields []ast.Field) string {
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

func GormField(field ast.Field, table string) string {
	var gormField = ""

	if field.Relation == nil || field.Relation.Type != "many-to-many" {
		gormField = "\t"

		gormField += ToUpperFirst(ToCamelCase(field.Name)) + "\t"
		if field.IsNull {
			gormField += "*"
		}
		gormField += ToLower(field.Type)
		gormField += "\t`json:\"" + ToSnakeCase(field.Name) + "\" gorm:\"" + GormAnnotations(field) + "\"`"
	}

	if field.Relation != nil {
		if field.Relation.Type != "many-to-many" {
			gormField += "\n"
		}

		gormField += "\t"

		gormField += ToUpperFirst(field.Relation.Table) + "\t"

		if field.IsNull {
			gormField += "*"
		}

		if field.Relation != nil && (field.Relation.Type == "one-to-many" || field.Relation.Type == "many-to-many") {
			gormField += "[]"
		}

		if field.Relation.Table == table {
			if !field.IsNull {
				gormField += "*"
			}
			gormField += ToUpperFirst(field.Relation.Table) + "Model\t"
		} else {
			gormField += ToLowerFirst(field.Relation.Table) + "Model." + ToUpperFirst(field.Relation.Table) + "Model\t"
		}

		gormField += "\t`json:\"" + ToSnakeCase(field.Relation.Table) + "\""

		if field.Relation != nil {
			switch field.Relation.Type {
			case "one-to-one":
				gormField += " gorm:\"foreignKey:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn)) + ";references:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn)) + "\""
			case "one-to-many":
				gormField += " gorm:\"foreignKey:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn)) + ";references:" + ToUpperFirst(ToCamelCase(field.Relation.RefColumn)) + "\""
			case "many-to-one":
				gormField += " gorm:\"foreignKey:" + ToUpperFirst(ToCamelCase(field.Name)) + "\""
			case "many-to-many":
				gormField += " gorm:\"many2many:" + ToSnakeCase(field.Relation.RefTable) + "\""
			}
		}
		gormField += "`"
	}

	return gormField
}

func DtoFieldNil(field ast.Field) string {
	return dtoField(field, true)
}

func DtoField(field ast.Field) string {
	return dtoField(field, false)
}

func dtoField(field ast.Field, allNull bool) string {
	var gormField = ""

	if field.Relation == nil || field.Relation.Type != "many-to-many" {
		gormField = "\t"

		gormField += ToUpperFirst(ToCamelCase(field.Name)) + "\t"
		if field.IsNull || allNull {
			gormField += "*"
		}
		gormField += ToLower(field.Type)
		gormField += "\t`json:\"" + ToSnakeCase(field.Name) + "\"`"
	}

	if field.Relation != nil && field.Relation.Type == "many-to-many" {

		gormField += "\t"

		gormField += ToUpperFirst(field.Relation.Table) + "\t"

		if field.IsNull || allNull {
			gormField += "*"
		}
		gormField += "[]"

		gormField += ToLowerFirst(field.Relation.Table) + "Model." + ToUpperFirst(field.Relation.Table) + "Model\t"
		gormField += "\t`json:\"" + ToSnakeCase(field.Relation.Table) + "\"`"

	}

	return gormField
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

func GenRoute(route ast.Route) string {
	routeStr := "group."
	routeStr += ToUpper(route.GetMethod())
	routeStr += "(\""
	routeStr += route.GetRoute()

	if route.GetRoute() == "" && len(route.GetPath()) == 0 {
		routeStr += "/"
	}

	for _, path := range route.GetPath() {

		if string(routeStr[len(routeStr)-1:]) != "/" {
			routeStr += "/"
		}

		routeStr += ":" + path.Name
	}

	routeStr += "\", handler."
	routeStr += ToUpperFirst(ToCamelCase(route.GetFunc()))

	return routeStr + ")"
}
