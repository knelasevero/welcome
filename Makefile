# set the shell to bash always
SHELL         := /bin/bash

# set make and shell flags to exit on errors
MAKEFLAGS     += --warn-undefined-variables
.SHELLFLAGS   := -euo pipefail -c

ARCH = amd64 arm64
BUILD_ARGS ?=

# default target is build
.DEFAULT_GOAL := all
.PHONY: all
all: $(addprefix build-,$(ARCH))

HELM_DIR    ?= deploy/charts/welcome

OUTPUT_DIR  ?= bin

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# ====================================================================================
# Colors

BLUE         := $(shell printf "\033[34m")
YELLOW       := $(shell printf "\033[33m")
RED          := $(shell printf "\033[31m")
GREEN        := $(shell printf "\033[32m")
CNone        := $(shell printf "\033[0m")

# ====================================================================================
# Logger

TIME_LONG	= `date +%Y-%m-%d' '%H:%M:%S`
TIME_SHORT	= `date +%H:%M:%S`
TIME		= $(TIME_SHORT)

INFO	= echo ${TIME} ${BLUE}[ .. ]${CNone}
WARN	= echo ${TIME} ${YELLOW}[WARN]${CNone}
ERR		= echo ${TIME} ${RED}[FAIL]${CNone}
OK		= echo ${TIME} ${GREEN}[ OK ]${CNone}
FAIL	= (echo ${TIME} ${RED}[FAIL]${CNone} && false)


# Image registry for build/push image targets
export IMAGE_REGISTRY ?= knelasevero/wecolme

# ====================================================================================
# Golang

.PHONY: test
test: ## Run tests
	@$(INFO) go test
	go test -race -v ./pkg/... -coverprofile cover.out
	@$(OK) go test

.PHONY: build
build: $(addprefix build-,$(ARCH)) ## Build binary

.PHONY: build-%
build-%: ## Build binary for the specified arch
	@$(INFO) go build $*
	@CGO_ENABLED=0 GOOS=linux GOARCH=$* \
		go build -o '$(OUTPUT_DIR)/welcome-linux-$*' main.go
	@$(OK) go build $*

lint.check: ## Check install of golanci-lint
	@if ! golangci-lint --version > /dev/null 2>&1; then \
		echo -e "\033[0;33mgolangci-lint is not installed: run \`\033[0;32mmake lint.install\033[0m\033[0;33m\` or install it from https://golangci-lint.run\033[0m"; \
		exit 1; \
	fi

lint.install: ## Install golangci-lint to the go bin dir
	@if ! golangci-lint --version > /dev/null 2>&1; then \
		echo "Installing golangci-lint"; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(GOBIN) v1.42.1; \
	fi

lint: lint.check ## Run golangci-lint
	@if ! golangci-lint run; then \
		echo -e "\033[0;33mgolangci-lint failed: some checks can be fixed with \`\033[0;32mmake fmt\033[0m\033[0;33m\`\033[0m"; \
		exit 1; \
	fi
	@$(OK) Finished linting

fmt: lint.check ## Ensure consistent code style
	@go mod tidy
	@go fmt ./...
	@golangci-lint run --fix > /dev/null 2>&1 || true
	@$(OK) Ensured consistent code style

## Docker

docker.build: $(addprefix build-,$(ARCH)) ## Build the docker image
	@$(INFO) docker build
	@docker build . $(BUILD_ARGS) -t $(IMAGE_REGISTRY):$(VERSION)
	@$(OK) docker build

docker.push: ## Push the docker image to the registry
	@$(INFO) docker push
	@docker push $(IMAGE_REGISTRY):$(VERSION)
	@$(OK) docker push

# RELEASE_TAG is tag to promote. Default is promoting to main branch, but can be overriden
# to promote a tag to a specific version.
RELEASE_TAG ?= main
SOURCE_TAG ?= $(VERSION)

docker.promote: ## Promote the docker image to the registry
	@$(INFO) promoting $(SOURCE_TAG) to $(RELEASE_TAG)
	docker manifest inspect $(IMAGE_REGISTRY):$(SOURCE_TAG) > .tagmanifest
	for digest in $$(jq -r '.manifests[].digest' < .tagmanifest); do \
		docker pull $(IMAGE_REGISTRY)@$$digest; \
	done
	docker manifest create $(IMAGE_REGISTRY):$(RELEASE_TAG) \
		$$(jq -j '"--amend $(IMAGE_REGISTRY)@" + .manifests[].digest + " "' < .tagmanifest)
	docker manifest push $(IMAGE_REGISTRY):$(RELEASE_TAG)
	@$(OK) docker push $(RELEASE_TAG) \

# ====================================================================================
# Helm Chart

HELM_VERSION ?= $(shell helm show chart $(HELM_DIR) | grep 'version:' | sed 's/version: //g')

helm.build: ## Build helm chart
	@$(INFO) helm package
	@helm package $(HELM_DIR) --dependency-update --destination $(OUTPUT_DIR)/chart
	@mv $(OUTPUT_DIR)/chart/welcome-$(HELM_VERSION).tgz $(OUTPUT_DIR)/chart/welcome.tgz
	@$(OK) helm package

# ====================================================================================
# Deploy

deploy: ## Deploy tag to a k8s cluster with kubeconfig contents
	@$(INFO) deploy tag to kubeconfig cluster
    ./deploy/scripts/deploy.sh $KUBECONFIGCONTENT $TAG
	@$(OK) deploy tag to kubeconfig cluster
