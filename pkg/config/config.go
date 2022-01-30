package config

import (
	"os"
)

var Port string
var Place string

func init() {
	Port = os.Getenv("PORT")
	Place = os.Getenv("PLACE")
	if Port == "" {
		Port = "8080"
	}

	if Place == "" {
		Port = "Place"
	}
}
