# decrypt

## pre-requisites
You will need to create a service account secret in namespace `argo-events`.
This service account will need to have PubSub read and write access.
1. Download the service account JSON as `key.json`
2. `kubectl create secret generic argo-secrets -n argo-events --from-file=key.json`

## Make
```bash
all                            Build and Push Docker Image
build                          Build the Docker Image
help                           List out all commands
install                        Install Helm Chart
push                           Push the Docker Image
```

## Build/Deploy Notes
There is a [Makefile](MakeFile) that provides commands to build and deploy each app.

1. Run the following command to build the Docker image and push it to GCR
```bash
PROJECT=<GCP Project> APP=decrypt TAG=v1 make build push
```
2. SSH over bastion host `gcloud beta compute ssh cov-bastion --tunnel-through-iap --project $CLUSTER_NAME --zone $CLUSTER_ZONE -- -L8888:127.0.0.1:8888`
3. In a new tab, run export HTTPS_PROXY=localhost:8888
4. Run the following command to roll out a new release
```bash
PROJECT=<GCP Project> APP=decrypt TAG=v1 make install
```
