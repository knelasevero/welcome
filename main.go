package main

import (
	"github.com/knelasevero/welcome/pkg/config"
	"github.com/knelasevero/welcome/pkg/routes"
	"log"
	"net/http"

	"github.com/rs/cors"
)

func main() {
	port := config.Port

	// Handle routes
	r := routes.Handlers()
	handler := cors.AllowAll().Handler(r)
	http.Handle("/", handler)

	// serve
	log.Printf("Server up on port '%s'", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
