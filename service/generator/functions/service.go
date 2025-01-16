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
