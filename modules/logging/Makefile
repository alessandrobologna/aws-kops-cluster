CI_BUILD_NUMBER ?= $(USER)-snapshot

VERSION ?= $(CI_BUILD_NUMBER)

IMAGE_NAME ?= "fluentd-cloudwatch"
REPO_NAME ?= "k8s/$(IMAGE_NAME)"
REGION ?= "us-east-1"

# use kubectl to determine the current cluster
CLUSTER ?= $(shell kubectl config view -o template --template='{{ index . "current-context" }}')

# create or get the ECR repo for $(REPO_NAME)
PUBLISH_TAG ?= $(shell aws ecr describe-repositories --repository-name $(REPO_NAME) --region $(REGION)\
    --query 'repositories[0].repositoryUri' --output text 2>/dev/null || aws ecr create-repository --repository-name $(REPO_NAME) --region $(REGION)\
    --query 'repository.repositoryUri' --output text ):$(VERSION)


.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'



package: ## packages the docker image
	@docker build -t $(PUBLISH_TAG) .

publish: package ## publish the docker image
	@eval $$(aws ecr get-login --no-include-email --region $(REGION)) && \
	docker push $(PUBLISH_TAG)

deploy: publish ## Deploy to k8s
	@CLUSTER=$(CLUSTER) REGION=$(REGION) PUBLISH_TAG=$(PUBLISH_TAG) sh -c '\
		envtpl < infra/logging-ns.yaml | kubectl apply -f - && \
		envtpl < infra/fluentd-cloudwatch-daemonset.yaml | kubectl apply -f - \
	'

remove:  ## Remove daemonset from k8s
	@CLUSTER=$(CLUSTER) REGION=$(REGION) PUBLISH_TAG=$(PUBLISH_TAG) sh -c '\
		envtpl < infra/fluentd-cloudwatch-daemonset.yaml | kubectl delete -f - && \
		envtpl < infra/logging-ns.yaml | kubectl delete -f - \
	'

