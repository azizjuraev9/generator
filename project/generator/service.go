package generator

import (
	"bytes"
	"fmt"
	"generator/project/generator/functions"
	"generator/service/model"
	"github.com/fobus1289/parser"
	"go/format"
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
				return ""
			}
			return value
		})

		result = filepath.Clean(result)
		result = strings.TrimSuffix(result, ".gohtml")
		result = strings.TrimPrefix(result, filepath.Clean(name))

		if info.IsDir() {
			dirs = append(dirs, result)
			return nil
		}

		// Open and add file to map regardless of whether it exists in destination
		f, err := os.Open(path)
		if err != nil {
			return err
		}
		files[result] = f

		return nil
	})

	return
}

func Generate(templatePath string, dest string, services []model.ServiceModel) {
	for _, service := range services {

		hasTranslatableFields := false
		if service.Multilingual {
			for _, field := range service.Ast.Table.Fields {
				hasTranslatableFields = hasTranslatableFields || field.IsTranslatable
			}
		}

		if !hasTranslatableFields && service.Multilingual {
			panic("Multilingual service must have at least one translatable field")
		}

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

			var outBuff = bytes.Buffer{}

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
				"GormField":    functions.GormField,
				"GenRoute":     functions.GenRoute,
				"DtoFieldNil":  functions.DtoFieldNil,
				"DtoField":     functions.DtoField,
			}).Parse(buff.String()))

			err = tmpl.Execute(&outBuff, map[string]interface{}{
				"Service":  service,
				"Services": services,
			})
			if err != nil {
				panic(err)
			}

			if strings.HasSuffix(name, ".go") {
				tmpFormat, err := format.Source(outBuff.Bytes())
				if err != nil {
					fmt.Println(outBuff.String())
					fmt.Println("Ошибка форматирования:", err)
					os.Exit(1)
				}

				newBuff := bytes.NewBuffer(tmpFormat)
				outBuff = *newBuff
			}

			//formatted := outBuff.Bytes()

			// Create output file
			outputPath := filepath.Join(dest, name)
			f, err := os.Create(outputPath)
			if err != nil {
				panic(err)
			}
			defer f.Close()

			if _, err := f.Write(outBuff.Bytes()); err != nil {
				return
			}
		}
	}
}
