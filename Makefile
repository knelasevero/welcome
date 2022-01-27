# ====================================================================================
# Golang

.PHONY: test
test: ## Run tests
	@$(INFO) go test
	go test -race -v ./pkg/... -coverprofile cover.out
	@$(OK) go test