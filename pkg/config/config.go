package config

import (
	"os"
)

var Port string

func init() {
	Port = os.Getenv("PORT")
	if Port == "" {
		Port = "80"
	}
}