.DEFAULT_GOAL := help
.PHONY: help

ENVIRONMENT ?= incoming
WORKDIR     ?= "/workspace/environments/$(ENVIRONMENT)"

help:  ## List out all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

format:  ## Format all .tf files
	@terraform fmt -recursive .

init: check-vars format  ## Initialize Terraform, Backends, and Plugins
	@docker-compose run tf 'cd $(WORKDIR) && terraform init -backend-config=bucket="$$TF_STATE_BUCKET" -backend-config=prefix="$$TF_STATE_PREFIX"'

plan: check-vars format  ## Create an executable plan in a Docker container (requires environment variables to be set)
	@docker-compose run tf 'cd $(WORKDIR) && terraform plan -no-color -out=tfplan'

apply: check-vars  ## Run the executable plan in a Docker container (requires environment variables to be set)
	@docker-compose run tf 'cd $(WORKDIR) && terraform apply -input=false -no-color tfplan'

up: plan apply  ## Create and run the executable plan in a Docker container (requires environment variables to be set)

cleanup:  ## Clean up all docker resources
	@docker-compose down --volumes --remove-orphans

check-vars:
ifndef GOOGLE_APPLICATION_CREDENTIALS
	$(error GOOGLE_APPLICATION_CREDENTIALS is undefined)
endif
