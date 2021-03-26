# About
This is a POC for a k8s container running a SFTP server

# Working with GKE
1. Login to Google cloud from the CLI

    $ gcloud auth login

2. Set the right project to work off

    $ gcloud config set project phd-project

3. Set the right docker registry auth

    $ gcloud auth configure-docker

# Testing
## Requirements
To test this locally, you'll need

1. Docker

## Building a local build

    $ make testbuild

## Running a local container

    $ make testrun

## Get a shell to the container

    $ make shell

## Clean the local container

    $ make clean

## Create official image
Container images are created from the commit hash of `HEAD` by

    $ make build

## Push official image

    $ make push

# Path to Production
## SFTP Server
- [x] Investigate sftpgo
- [x] Have support for virtual users
- [x] Have support for chrooted virtual directories as users login
- [x] Check support for adding to Cloud buckets directly
- [x] Configure log output
- [x] Do we need to have a bucket per user or a single bucket for all users?
- [x] Have an image built and send to gcr.io

## Secrets
- [x] Check in SFTP server secrets to secrets manager
- [x] Have secrets manager mounts visible on the container
- [x] SFTP server should pick up keys from the secrets mount

## Keys Partition
- [x] ~Can the same partition be mounted as readOnly on >1 k8s replicas?~
- [x] Have support for GCS buckets for key retrieval
- [x] Have a strategy to add new keys to the partition as userbase expands

## Networking
- [x] Check if we have domains purchased?
- [x] Talk to Keith/Karl on how we can add the NetDev tickets for setting up phd.innovations.stanford.edu
- [x] Investigate anycast for the two LB configuration

## Multi-Region
- [x] Have the cluster running in virginia

## Scaling
- [x] Setup terraform on the cluster
- [x] Autoscaling strategy on k8s deployment
- [x] Figure out container requests and limits on CPU and mem
- [x] Can the LB factor into CPU utilization to determine the destination?
- [ ] Automate deployment via a pipeline

## Testing
- [ ] Document testing scenarios on git
- [ ] Work on a testing framework to test upto a million SFTP users

## Security
- [x] Investigate fail2ban in sftpgo
- [x] Document all security settings in sftpgo
- [ ] How do we limit the number of failed attempts in sftpgo
- [ ] How do we monitor/thwart DOS attacks on the LB?
- [ ] Have a way to generate secrets for production via kustomization.yaml
- [x] Disable all login methods except "publickey"

## Troubleshooting
- [x] Logs sent to stdout from the containers
- [ ] Logs from sftp server/ssh should be sent to Cloud Logging
- [ ] Scripts to run on logs to parse them and get helpful metrics
- [ ] Log based metrics to prevent attacks
- [ ] Prometheus/Grafana
- [ ] Any other metrics?
