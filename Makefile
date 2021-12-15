ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

GO_VERSION ?= 1.14
GO := $(or $(shell which go$(GO_VERSION)),$(shell which go))

OS := $(shell $(GO) env GOOS)
ARCH := $(shell $(GO) env GOARCH)

BIN?=$(ROOT_DIR)/.bin
COSIGN_VERSION := 1.4.1
COSIGN := $(BIN)/cosign-$(COSIGN_VERSION)

$(BIN):
	mkdir -p $(BIN)

$(COSIGN): $(BIN)
	curl -sSL -o $(COSIGN) https://github.com/sigstore/cosign/releases/download/v$(COSIGN_VERSION)/cosign-$(OS)-$(ARCH) && \
	chmod +x $(COSIGN)

IMAGE_DOCKERFILES:=$(wildcard $(ROOT_DIR)/dockerfiles/*.dockerfile)
IMAGE_TARGETS:= $(patsubst $(ROOT_DIR)/dockerfiles/%.dockerfile,%,$(IMAGE_DOCKERFILES))

COMMIT:=$(shell git rev-list -1 HEAD)
VERSION:=$(COMMIT)

REGISTRY:=ghcr.io/ribbybibby

.SECONDEXPANSION:
testy.REQUIREMENTS:= 

SIGN_ALL_IMAGES:= $(addprefix sign-image-,$(IMAGE_TARGETS))
sign-all-images: $(SIGN_ALL_IMAGES)
$(SIGN_ALL_IMAGES): sign-image-%: $(COSIGN)
	@echo "==> Signing $(REGISTRY)/$*:$(VERSION)"
	$(COSIGN) sign $(REGISTRY)/$*:$(VERSION)
	$(COSIGN) verify $(REGISTRY)/$*:$(VERSION)
	@echo "==> Signed and verified $(REGISTRY)/$*:$(VERSION)"

BUILD_ALL_IMAGES:= $(addprefix build-image-,$(IMAGE_TARGETS))
build-all-images: $(BUILD_ALL_IMAGES)
$(BUILD_ALL_IMAGES): build-image-%: $(ROOT_DIR)/dockerfiles/%.dockerfile $$(%.REQUIREMENTS)
	@echo "==> Building $(REGISTRY)/$*:$(VERSION)"
	docker build . --file $< --tag $(REGISTRY)/$*:$(VERSION)
	@echo "==> Built $(REGISTRY)/$*:$(VERSION) successfully"

PUSH_ALL_IMAGES:= $(addprefix push-image-,$(IMAGE_TARGETS))
push-all-images: $(PUSH_ALL_IMAGES)
$(PUSH_ALL_IMAGES): push-image-%:
	@echo "==> Pushing $(REGISTRY)/$* with tags '$(VERSION)' and 'latest'"
	docker tag $(REGISTRY)/$*:$(VERSION) $(REGISTRY)/$*:latest
	docker push $(REGISTRY)/$*:$(VERSION)
	docker push $(REGISTRY)/$*:latest
	@echo "==> Pushed $(REGISTRY)/$* with tags '$(VERSION)' and 'latest'"
