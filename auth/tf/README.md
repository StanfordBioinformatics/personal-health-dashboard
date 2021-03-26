# tf

## Prerequisites

### Dependencies
- _docker_ to be installed using [this link](https://docs.docker.com/v17.09/engine/installation/).
- _docker-compose_ to be installed using [this link](https://docs.docker.com/compose/install/)

## How To Run

### Environment
The following environment variables need to be set:
1. `GOOGLE_APPLICATION_CREDENTIALS`
  -  Provide authentication credentials to your application code by setting this environment variable.
2. `CLUSTER_PROJECT`
  - This is the name of the target GCP Project. For phd-project Project, this should be: "phd-prj-phd-project".

### Make Commands
Run the command `make` to list all commands (as shown below):
```
apply           Run the executable plan in a Docker container (requires environment variables to be set)
format          Format all .tf files
help            List out all commands
init            Initialize Terraform, Backends, and Plugins
plan            Create an executable plan in a Docker container (requires environment variables to be set)
up              Create and run the executable plan in a Docker container (requires environment variables to be set)
```

### Run Make Commands
How to init and run a plan for phd-project
```bash
CLUSTER_PROJECT=phd-project make init plan
```

How to init and run a plan for phd-project
```bash
CLUSTER_PROJECT=phd-prj-phd-project make init plan
```

How to run and apply changes for phd-project
```bash
CLUSTER_PROJECT=phd-project make up
```

How to run and apply changes for phd-project
```bash
CLUSTER_PROJECT=phd-prj-phd-project make up
```

### Clean up all docker instances
```bash
docker-compose down --volumes --remove-orphans
```