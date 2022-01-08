# tf

## Prerequisites

### Dependencies
- _docker_ to be installed using [this link](https://docs.docker.com/v17.09/engine/installation/).
- _docker-compose_ to be installed using [this link](https://docs.docker.com/compose/install/)

## How To Run

### Environment
Make a copy of `.env.example` as `.env` and set the required environment variables.

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
How to init and run a plan
```bash
make init plan
```

How to run and apply changes
```bash
make up
```

### Clean up all docker instances
```bash
docker-compose down --volumes --remove-orphans
```
