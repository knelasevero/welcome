package routes

import (
	"github.com/knelasevero/welcome/pkg/controllers"

	"github.com/gorilla/mux"

)

// Handlers register routes
func Handlers() *mux.Router {
	r := mux.NewRouter().StrictSlash(true)

	r.HandleFunc("/", controllers.Welcome).Methods("GET")

	return r
}

