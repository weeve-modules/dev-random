# import config.
# You can change the default config with `make cnf="config_special.env" build`
cnf ?= config.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

# import deploy config
# You can change the default deploy config with `make cnf="deploy_special.env" release`
dpl ?= deploy.env
include $(dpl)
export $(shell sed 's/=.*//' $(dpl))

# # grep the version from the mix file
# VERSION=$(shell ./version.sh)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


# DOCKER TASKS
# Build the container
build: ## Build the container
	docker build -t $(ACCOUNT_NAME)/$(APP_NAME) . -f image/Dockerfile

# build-nc: ## Build the container without caching
# 	docker build --no-cache -t $(APP_NAME) .

run: ## Run container on port configured in `config.env`
	docker run -i -t --rm --env-file=./config.env \
		--volume $(VOLUME_HOST):$(VOLUME_CONTAINER) \
		-p $(PORT):$(PORT) --name="$(APP_NAME)" \
		-e EGRESS_API_HOST=localhost \
		$(ACCOUNT_NAME)/$(APP_NAME) --hash sha256 --interval=2

listen: ## Pull and start a listener
	docker run --detach -e PORT=$(PORT) -e LOG_HTTP_BODY -e LOG_HTTP_HEADERS -p $(PORT):$(PORT) jmalloc/echo-server

up: build run ## Run container on port configured in `config.env` (Alias to run)

# check:
# 	docker pushrm2 --version
# ifeq (, $(shell which docker pushrm))
# $(error "No lzop in $(PATH), consider doing apt-get install lzop")
# endif

listentest: ## Run a listener container and receive messages from this container
	docker network create $(NETWORK_NAME) || true
	docker run --detach --network=$(NETWORK_NAME) --rm \
		-e PORT=4000 \
		-e LOG_HTTP_BODY=true \
		-e LOG_HTTP_HEADERS=true \
		--name echo jmalloc/echo-server
	docker run \
		--network=$(NETWORK_NAME) --rm \
		--volume $(VOLUME_HOST):$(VOLUME_CONTAINER) \
		-e EGRESS_API_HOST=echo \
		-e PORT=4000 \
		-e VOLUME_CONTAINER=/mnt/random \
		$(ACCOUNT_NAME)/$(APP_NAME) --hash sha256 --interval=2

push: ## Push to dockerhub, needs credentials!
	docker push $(ACCOUNT_NAME)/$(APP_NAME):latest

pushrm: ## Push to dockerhub AND add description, needs additionally the pushrm tool!
## https://github.com/christian-korneck/docker-pushrm
	docker push $(ACCOUNT_NAME)/$(APP_NAME):latest
	docker pushrm $(ACCOUNT_NAME)/$(APP_NAME):latest --short $(DESCRIPTION)

# docker run --rm -t \
# 	-v $(pwd):/myvol \
# 	-e DOCKER_USER='my-user' -e DOCKER_PASS='my-pass' \
# 	chko/docker-pushrm:1 --file /myvol/README.md \
# 	--short "My short description" --debug my-user/my-repo
# stop: ## Stop and remove a running container
# 	docker stop $(APP_NAME); docker rm $(APP_NAME)

# release: build-nc publish ## Make a release by building and publishing the `{version}` ans `latest` tagged containers to ECR

# Docker publish
# publish: repo-login publish-latest publish-version ## Publish the `{version}` ans `latest` tagged containers to ECR

# publish-latest: tag-latest ## Publish the `latest` taged container to ECR
# 	@echo 'publish latest to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):latest

# publish-version: tag-version ## Publish the `{version}` taged container to ECR
# 	@echo 'publish $(VERSION) to $(DOCKER_REPO)'
# 	docker push $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# # Docker tagging
# tag: tag-latest tag-version ## Generate container tags for the `{version}` ans `latest` tags

# tag-latest: ## Generate container `{version}` tag
# 	@echo 'create tag latest'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):latest

# tag-version: ## Generate container `latest` tag
# 	@echo 'create tag $(VERSION)'
# 	docker tag $(APP_NAME) $(DOCKER_REPO)/$(APP_NAME):$(VERSION)

# # HELPERS

# # generate script to login to aws docker repo
# CMD_REPOLOGIN := "eval $$\( aws ecr"
# ifdef AWS_CLI_PROFILE
# CMD_REPOLOGIN += " --profile $(AWS_CLI_PROFILE)"
# endif
# ifdef AWS_CLI_REGION
# CMD_REPOLOGIN += " --region $(AWS_CLI_REGION)"
# endif
# CMD_REPOLOGIN += " get-login --no-include-email \)"

# # login to AWS-ECR
# repo-login: ## Auto login to AWS-ECR unsing aws-cli
# 	@eval $(CMD_REPOLOGIN)

# version: ## Output the current version
# 	@echo $(VERSION)

build_and_push_multi_platform:
	docker buildx build --platform linux/amd64,linux/arm,linux/arm64 -t $(ACCOUNT_NAME)/$(APP_NAME) --push . -f image/Dockerfile
.phony: create_and_push_multi_platform
