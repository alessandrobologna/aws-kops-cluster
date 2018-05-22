CLOUD_PROVIDER ?= "AWS"
IMAGE ?= "k8s.gcr.io/cluster-autoscaler:v1.1.0"
MIN_NODES ?= 3
MAX_NODES ?= 6
AWS_REGION ?= $(shell aws configure get region)
# use kubectl to determine the current cluster
CLUSTER ?= $(shell kubectl config view -o template --template='{{ index . "current-context" }}')
GROUP_NAME ?= "nodes.$(CLUSTER)"
SSL_CERT_PATH ?= "/etc/ssl/certs/ca-certificates.crt"
.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

deploy: ## Deploy to k8s
	CLOUD_PROVIDER=$(CLOUD_PROVIDER) IMAGE=$(IMAGE) MIN_NODES=$(MIN_NODES) MAX_NODES=$(MAX_NODES) AWS_REGION=$(AWS_REGION) CLUSTER=$(CLUSTER) GROUP_NAME=$(GROUP_NAME) SSL_CERT_PATH=$(SSL_CERT_PATH) \
	sh -c '\
		envtpl < infra/cluster-autoscaler.yml | kubectl apply -f - \
	'

delete: ## Deploy to k8s
	CLOUD_PROVIDER=$(CLOUD_PROVIDER) IMAGE=$(IMAGE) MIN_NODES=$(MIN_NODES) MAX_NODES=$(MAX_NODES) AWS_REGION=$(AWS_REGION) CLUSTER=$(CLUSTER) GROUP_NAME=$(GROUP_NAME) SSL_CERT_PATH=$(SSL_CERT_PATH) \
	sh -c '\
		envtpl < infra/cluster-autoscaler.yml | kubectl delete -f - \
	'

