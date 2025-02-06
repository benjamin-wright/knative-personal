MAKEFLAGS += --always-make

CLUSTER_NAME ?= knative-test
KUBECONFIG ?= .scratch/kubeconfig.yaml
REGISTRY_NAME ?= wasm-registry.localhost
REGISTRY_PATH ?= $(REGISTRY_NAME):5000/$(USER)

ARCH ?= $(shell uname -m)
ifeq ($(ARCH),arm64)
	ARCH=aarch64
endif

.PHONY: k3s-wasm
k3s-wasm:
	docker buildx build \
		-t k3s-wasm \
		--platform=linux/$(ARCH) \
		--build-arg ARCH=$(ARCH) \
		--output=type=docker \
		- < docker/k3s-wasm.Dockerfile

.PHONY: start
start: k3s-wasm cluster infra

# See here: https://www.cncf.io/blog/2024/03/28/webassembly-on-kubernetes-the-practice-guide-part-02/
.PHONY: cluster
cluster:
	docker pull registry:2

	k3d cluster create $(CLUSTER_NAME) \
		--registry-create $(REGISTRY_NAME) \
		--image k3s-wasm \
		--k3s-arg '--disable=traefik@server:*' \
		--kubeconfig-update-default=false

	mkdir -p .scratch
	k3d kubeconfig get $(CLUSTER_NAME) > $(KUBECONFIG)

infra:
	helmfile --kubeconfig=$(PWD)/$(KUBECONFIG) apply -f ./infra/helmfile.yaml --selector name=knative-operator
	helmfile --kubeconfig=$(PWD)/$(KUBECONFIG) apply -f ./infra/helmfile.yaml

.PHONY: stop
stop:
	k3d cluster delete $(CLUSTER_NAME)
	rm -rf .scratch
