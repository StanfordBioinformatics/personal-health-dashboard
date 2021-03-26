.DEFAULT_GOAL := help
.PHONY: help

PROJECT   ?= phd-project
TAG       ?= latest
NAMESPACE ?= ml

help:  ## List out all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: check-vars  ## Build the Docker Image
	@docker build -t gcr.io/$(PROJECT)/$(APP):$(TAG) $(APP)

push: check-vars  ## Push the Docker Image
	@docker push gcr.io/$(PROJECT)/$(APP):$(TAG)

build-all:  ## Build all Docker Images
	$(MAKE) APP=trainference build
	$(MAKE) APP=preprocessing build
	$(MAKE) APP=inference build

push-all:  ## Push all Docker Images
	$(MAKE) APP=trainference push
	$(MAKE) APP=preprocessing push
	$(MAKE) APP=inference push

all:  ## Build and Push all Docker Images
	$(MAKE) build-all push-all

install:  ## Install Helm Chart
	@helm upgrade --install $(APP) \
		./.helm/workers \
		-f ./.helm/values-$(APP).yaml \
		--set image.tag=$(TAG) \
		--set image.repository=gcr.io/$(PROJECT)/$(APP) \
		--set projectID=$(PROJECT) \
		--namespace $(NAMESPACE) \
		--wait --timeout 100s --atomic --debug


check-vars:
ifndef APP
	$(error APP is undefined - set of one trainference|preprocessing|inference)
endif
