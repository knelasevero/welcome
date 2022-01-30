package controllers

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/knelasevero/welcome/pkg/config"
)

func TestUpperCaseHandler(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	Welcome(w, req)
	res := w.Result()
	defer res.Body.Close()
	data, err := ioutil.ReadAll(res.Body)
	if err != nil {
		t.Errorf("expected error to be nil got %v", err)
	}
	expected := fmt.Sprintf("{\"message\": \"Welcome to %s\"}", config.Place)
	if string(data) != expected {
		t.Errorf("expected %s got %s", expected, string(data))
	}
}
