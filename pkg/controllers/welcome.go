package controllers

import (
	"fmt"
	"net/http"
)

func Welcome(w http.ResponseWriter, r *http.Request) {
	place := "place"
	w.Write([]byte(fmt.Sprintf("{\"message\": \"Welcome to %s\"}", place)))
}
