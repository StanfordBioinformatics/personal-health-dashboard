.DEFAULT_GOAL := help
.PHONY: help

help:  ## List out all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

format:  ## Format all .tf files
	@terraform fmt

init: check-vars format  ## Initialize Terraform, Backends, and Plugins
	@docker-compose run tf "terraform init -backend-config=config/$(CLUSTER_PROJECT).tfbackend"

plan: format check-vars  ## Create an executable plan in a Docker container (requires environment variables to be set)
	@docker-compose run tf "terraform plan -no-color -var-file=config/$(CLUSTER_PROJECT).tfvars -out=tfplan"

apply: check-vars  ## Run the executable plan in a Docker container (requires environment variables to be set)
	@docker-compose run tf "terraform apply -input=false -no-color tfplan"

up: plan apply  ## Create and run the executable plan in a Docker container (requires environment variables to be set)

cleanup:  ## Clean up all docker resources
	@docker-compose down --volumes --remove-orphans

check-vars:
ifndef GOOGLE_APPLICATION_CREDENTIALS
	$(error GOOGLE_APPLICATION_CREDENTIALS is undefined)
endif
ifndef CLUSTER_PROJECT
	$(error CLUSTER_PROJECT is undefined)
endif