# workers

## pre-requisites
You will need to create a service account secret in namespace `argo-events`.
This service account will need to have PubSub read and write access.
1. Download the service account JSON as `key.json`
2. `kubectl create secret generic argo-secrets -n argo-events --from-file=key.json`

## Make
```bash
all                            Build and Push all Docker Images
build-all                      Build all Docker Images
build                          Build the Docker Image
help                           List out all commands
install                        Install Helm Chart
push-all                       Push all Docker Images
push                           Push the Docker Image
```