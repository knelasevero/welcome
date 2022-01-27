package controllers

import (
	"fmt"
	"net/http"
)

var Place string

func Welcome(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte(fmt.Sprintf("{\"message\": \"Welcome to %s\"}", Place)))
}

func init(){
	Place = "place"
}
