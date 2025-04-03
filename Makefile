MAKEFLAGS += --always-make

CLUSTER_NAME ?= knative-test
KUBECONFIG ?= .scratch/kubeconfig.yaml
REGISTRY_NAME ?= wasm-registry.localhost
REGISTRY_PATH ?= $(REGISTRY_NAME):5000/$(USER)

IMAGE ?= test-image

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
		-p '9080:80@loadbalancer' -p '9443:443@loadbalancer' \
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

image:
	cd apps/svc1 && cargo build --release
	mkdir -p .build
	cp apps/svc1/target/wasm32-wasip1/release/wasm.wasm .build/wasm.wasm
	docker build -t $(IMAGE) -f docker/wasm.Dockerfile .build

rust:
	docker build --platform linux/aarch64 -t $(IMAGE) -f docker/rust.Dockerfile apps/svc1
