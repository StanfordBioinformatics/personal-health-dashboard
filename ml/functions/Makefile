
.DEFAULT_GOAL := help
.PHONY: help

help:  ## List out all commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deploy-trainference:  ## Deploy trainference Cloud Function
	@gcloud functions deploy cov-trainference-pub \--entry-point preprocessing \
  	--runtime python37 --trigger-http --allow-unauthenticated --source cov-trainference --allow-unauthenticated
