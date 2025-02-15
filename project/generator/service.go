package generator

import (
	"bytes"
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

func GetNestedFieldValue(obj interface{}, fieldPath string) string {
	v := reflect.ValueOf(obj)

	// Ensure we are dealing with a struct or a pointer to a struct
	if v.Kind() == reflect.Ptr {
		v = v.Elem() // Dereference pointer
	}

	if v.Kind() != reflect.Struct {
		panic("expected a struct or pointer to struct")
	}

	// Split fieldPath into parts
	fields := strings.Split(fieldPath, ".")

	for _, fieldName := range fields {
		// Get field by name
		v = v.FieldByName(fieldName)

		// Check if field exists
		if !v.IsValid() {
			panic("field not found")
		}

		// Dereference pointer if the field is a pointer
		if v.Kind() == reflect.Ptr {
			v = v.Elem()
		}
	}

	return v.Interface().(string)
}

func Dirname(name string, service model.ServiceModel) (dirs []string, files map[string]io.ReadCloser) {

	files = make(map[string]io.ReadCloser)

	filepath.Walk(name, func(path string, info fs.FileInfo, err error) error {
		if err != nil || path == name {
			return nil
		}

		p := parser.NewParser(path)

		result := parser.ReplaceWithTokens(path, p.ParsePlaceholders(), func(key string) string {
			return GetNestedFieldValue(service, key)
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

		for _, dir := range dirs {
			dir := filepath.Join(dest, dir)
			os.MkdirAll(dir, 0755)
		}

		for name, file := range files {
			f, err := os.Create(filepath.Join(dest, name))
			defer file.Close()
			if err != nil {
				panic(err)
			}
			defer f.Close()

			var buff bytes.Buffer

			io.Copy(&buff, file)

			tmpl := template.Must(template.New(f.Name()).Funcs(template.FuncMap{
				"ToUpper":      functions.ToUpper,
				"ToLower":      functions.ToLower,
				"ToTitle":      functions.ToTitle,
				"ToUpperFirst": functions.ToUpperFirst,
				"ToLowerFirst": functions.ToLowerFirst,
				"ToCamelCase":  functions.ToCamelCase,
				"ToSnakeCase":  functions.ToSnakeCase,
			}).Parse(buff.String()))
			tmpl.Execute(f, service)
		}
	}

}
