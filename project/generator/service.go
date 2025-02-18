package generator

import (
	"bytes"
	"fmt"
	"generator/project/generator/functions"
	"generator/service/model"
	"github.com/fobus1289/parser"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"text/template"
)

func GetNestedFieldValue(obj interface{}, fieldPath string) (string, error) {
	v := reflect.ValueOf(obj)

	// Ensure we are dealing with a struct or a pointer to a struct
	if v.Kind() == reflect.Ptr {
		v = v.Elem() // Dereference pointer
	}

	if v.Kind() != reflect.Struct {
		return "", fmt.Errorf("expected a struct or pointer to struct, got %v", v.Kind())
	}

	// Split fieldPath into parts
	fields := strings.Split(fieldPath, ".")

	for _, fieldName := range fields {
		// Get field by name
		v = v.FieldByName(fieldName)

		// Check if field exists
		if !v.IsValid() {
			return "", fmt.Errorf("field %s not found", fieldName)
		}

		// Dereference pointer if the field is a pointer
		if v.Kind() == reflect.Ptr {
			if v.IsNil() {
				return "", fmt.Errorf("field %s is nil", fieldName)
			}
			v = v.Elem()
		}
	}

	// Convert the final value to string
	return fmt.Sprint(v.Interface()), nil
}

func Dirname(name string, service model.ServiceModel) (dirs []string, files map[string]io.ReadCloser) {

	files = make(map[string]io.ReadCloser)

	filepath.Walk(name, func(path string, info fs.FileInfo, err error) error {
		if err != nil || path == name {
			return nil
		}

		p := parser.NewParser(path)

		result := parser.ReplaceWithTokens(path, p.ParsePlaceholders(), func(key string) string {
			value, err := GetNestedFieldValue(service, key)
			if err != nil {
				// Handle error appropriately - maybe log it and return a default value
				return ""
			}
			return value
		})

		result = filepath.Clean(result)

		result = strings.TrimSuffix(result, ".tpl")

		result = strings.TrimPrefix(result, filepath.Clean(name))

		if info.IsDir() {
			dirs = append(dirs, result)
			return nil
		}

		if _, err := os.Stat(filepath.Join(".", result)); err == nil {
			return nil
		}

		f, err := os.Open(path)
		{
			if err != nil {
				return err
			}
		}
		files[result] = f

		return nil
	})

	return
}

func Generate(templatePath string, dest string, services []model.ServiceModel) {
	for _, service := range services {
		dirs, files := Dirname(templatePath, service)

		// Create directories
		for _, dir := range dirs {
			dir := filepath.Join(dest, dir)
			os.MkdirAll(dir, 0755)
		}

		// Process each file
		for name, file := range files {
			// Read template content
			var buff bytes.Buffer
			_, err := io.Copy(&buff, file)
			if err != nil {
				panic(err)
			}
			file.Close()

			// Create output file
			outputPath := filepath.Join(dest, name)
			f, err := os.Create(outputPath)
			if err != nil {
				panic(err)
			}

			// Create and execute template
			tmpl := template.Must(template.New(name).Funcs(template.FuncMap{
				"ToUpper":      functions.ToUpper,
				"ToLower":      functions.ToLower,
				"ToTitle":      functions.ToTitle,
				"ToUpperFirst": functions.ToUpperFirst,
				"ToLowerFirst": functions.ToLowerFirst,
				"ToCamelCase":  functions.ToCamelCase,
				"ToSnakeCase":  functions.ToSnakeCase,
				"ResolveValue": functions.ResolveValue,
				"GormFields":   functions.GormFields,
			}).Parse(buff.String()))

			err = tmpl.Execute(f, map[string]interface{}{
				"Service":  service,
				"Services": services,
			})
			if err != nil {
				panic(err)
			}

			f.Close()
		}
	}
}
