NAME    := phd-frontend-auth
HASH    ?= $(shell git rev-parse --short HEAD)
GOOPTS  := -ldflags "-w -extldflags -static"
PROJECT ?= phd-project

build:
	docker build -t gcr.io/$(PROJECT)/sftp-go:$(HASH) -f ./sftpgo/Dockerfile .

push:
	docker push gcr.io/$(PROJECT)/sftp-go:$(HASH)

sinkbuild:
	docker build -t gcr.io/$(PROJECT)/sink:$(HASH) ./sink

sinkpush:
	docker push gcr.io/$(PROJECT)/sink:$(HASH)

testrun:
	-rm -rf $(PWD)/logs
	-mkdir $(PWD)/logs
	docker run \
  --name=$(NAME) \
  --hostname=$(NAME) \
  -p 2222:22 \
  -v $(PWD)/test_keys:/mnt/keys:ro \
  -v $(PWD)/test_secrets:/secrets:ro \
  -v $(PWD)/logs:/logs \
  gcr.io/$(PROJECT)/sftp-go:$(HASH)

run:
	-rm -rf $(PWD)/logs
	-mkdir $(PWD)/logs
	docker run \
  --name=$(NAME) \
  --hostname=$(NAME) \
  -p 2222:22 \
  -v $(PWD)/test_keys:/mnt/keys:ro \
  -v $(PWD)/test_secrets:/secrets:ro \
  -v $(PWD)/logs:/logs \
  gcr.io/$(PROJECT)/sftp-go:$(HASH)

shell:
	docker exec -it $(NAME) bash

clean:
	docker rm $(NAME)

# Helm
RELEASE_NAME = phd
CHART_DIR = helm/charts
MANIFEST_DIR = helm/manifests
VALUE_DIR = helm/values
values = $(wildcard $(VALUE_DIR)/*)
charts = $(subst $(VALUE_DIR),$(CHART_DIR),$(basename $(values)))
manifests = $(subst $(CHART_DIR),$(MANIFEST_DIR),$(charts))


# Render Helm charts
helm: $(manifests)

$(manifests): $(charts) $(values)
	mkdir -p $(MANIFEST_DIR)
	helm template --output-dir $(MANIFEST_DIR) \
               --name $(RELEASE_NAME) \
               --namespace $(notdir $@) \
               --values $(VALUE_DIR)/$(notdir $@).yaml \
               $(CHART_DIR)/$(notdir $@)

$(CHART_DIR)/prometheus-operator:
	mkdir -p $(dir $@)
	helm fetch --repo https://kubernetes-charts.storage.googleapis.com  --untar --untardir $(dir $@) --version 8.12.13 $(notdir $@)
