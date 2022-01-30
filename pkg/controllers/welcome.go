package controllers

import (
	"fmt"
	"net/http"

	"github.com/knelasevero/welcome/pkg/config"
)

var Place string

func Welcome(w http.ResponseWriter, r *http.Request) {
	_, err := w.Write([]byte(fmt.Sprintf("{\"message\": \"Welcome to %s\"}", config.Place)))
	if err != nil {
		fmt.Println(err.Error())
		w.WriteHeader(500)
		return
	}
}
