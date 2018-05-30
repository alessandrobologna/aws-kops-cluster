DOMAIN ?= example.com # domain for the cluster 
NAME ?= kops 
KOPS_STATE_STORE ?= s3://state-store.${NAME}.${DOMAIN}
NODE_COUNT ?= 3 
MASTER_COUNT ?= 3
NODE_ZONES ?= "us-east-2a,us-east-2b,us-east-2c"
MASTER_ZONES ?= "us-east-2a,us-east-2b,us-east-2c"
NODE_SIZE ?= "t2.micro"
MASTER_SIZE ?= "t2.micro"
SSH_PUBLIC_KEY ?= "pemfile.pem"
TOPOLOGY ?= "private"
NETWORKING ?= "weave"
NETWORK_CIDR ?= "10.0/16"



.PHONY: help

help: defaults
	@echo "Commands:"
	@echo "------------------------------"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo

defaults:
	@echo 
	@echo "Environment defaults:"
	@echo "------------------------------"
	@grep -E '^[a-zA-Z_-]+\s*\?=\s*.*$$' $(MAKEFILE_LIST) | sort |  awk 'BEGIN {FS = "\\?= *|#*"}; {printf "\033[33m%-30s\033[0m %s \033[37m %s\033[0m\n", $$1, $$2, $$3}'
	@echo


package: ## packages the docker image
	@docker build -t $(PUBLISH_TAG) .

publish: package ## publish the docker image
	@eval $$(aws ecr get-login --no-include-email --region $(REGION)) && \
	docker push $(PUBLISH_TAG)

deploy: publish ## Deploy to k8s
	@CLUSTER=$(CLUSTER) REGION=$(REGION) PUBLISH_TAG=$(PUBLISH_TAG) sh -c '\
		envtpl < infra/statting-ns.yaml | kubectl apply -f - && \
		envtpl < infra/fluentd-statsd-daemonset.yaml | kubectl apply -f - \
	'

cluster: ## Build the Kubernetes cluster
	@kops create cluster \
		--state $(KOPS_STATE_STORE) \
		--node-count $(NODE_COUNT) \
		--master-count $(MASTER_COUNT) \
		--zones $(NODE_ZONES) \
		--master-zones $(MASTER_ZONES) \
		--node-size $(NODE_SIZE) \
		--master-size $(MASTER_SIZE) \
		--ssh-public-key $(SSH_PUBLIC_KEY) \
		--topology $(TOPOLOGY) \
		--networking $(NETWORKING) \
		--network-cidr $(NETWORK_CIDR) \ 
		--name $(NAME).$(DOMAIN) \
		--bastion 

bucket: ## Create the state bucket
	@aws s3api create-bucket \
		--bucket state-store.$(NAME).$(DOMAIN) 
	@aws s3api put-bucket-versioning \
		--bucket state-store.$(NAME).$(DOMAIN) \
		--versioning-configuration Status=Enabled	