# VERSION
VERSION?=$(shell git describe --abbrev=0)+hash.$(shell git rev-parse --short HEAD)

# CONTAINER_RUNTIME
CONTAINER_RUNTIME?=$(shell which docker)

# BUILD_IMAGE
BUILD_IMAGE_REGISTRY_HOST?=docker.io
BUILD_IMAGE_NAMESPACE=library
BUILD_IMAGE_REPOSITORY=golang
BUILD_IMAGE_VERSION?=1.16
BUILD_IMAGE_FULLY_QUALIFIED:=${BUILD_IMAGE_REGISTRY_HOST}/${BUILD_IMAGE_NAMESPACE}/${BUILD_IMAGE_REPOSITORY}:${BUILD_IMAGE_VERSION}

# BASE_IMAGE
BASE_IMAGE_REGISTRY_HOST?=docker.io
BASE_IMAGE_NAMESPACE=library
BASE_IMAGE_REPOSITORY=busybox
BASE_IMAGE_VERSION?=latest
BASE_IMAGE_FULLY_QUALIFIED=${BASE_IMAGE_REGISTRY_HOST}/${BASE_IMAGE_NAMESPACE}/${BASE_IMAGE_REPOSITORY}:${BASE_IMAGE_VERSION}

# CONTAINER_IMAGE
CONTAINER_IMAGE_REGISTRY_HOST?=docker.io
CONTAINER_IMAGE_NAMESPACE=volkerraschek
CONTAINER_IMAGE_REPOSITORY=getpsrc
CONTAINER_IMAGE_VERSION?=latest
CONTAINER_IMAGE_FULLY_QUALIFIED=${CONTAINER_IMAGE_REGISTRY_HOST}/${CONTAINER_IMAGE_NAMESPACE}/${CONTAINER_IMAGE_REPOSITORY}:${CONTAINER_IMAGE_VERSION}
CONTAINER_IMAGE_UNQUALIFIED=${CONTAINER_IMAGE_NAMESPACE}/${CONTAINER_IMAGE_REPOSITORY}:${CONTAINER_IMAGE_VERSION}

# EXECUTABLES
# ==============================================================================
EXECUTABLE_TARGETS=getpsrc

PHONY=all
all: clean ${EXECUTABLE_TARGETS}

getpsrc:
	GOPRIVATE=$(shell go env GOPRIVATE) \
	GOPROXY=$(shell go env GOPROXY) \
	GONOPROXY=$(shell go env GONOPROXY) \
	GONOSUMDB=$(shell go env GONOSUMDB) \
	GOSUMDB=$(shell go env GOSUMDB) \
		go build -tags netgo -ldflags "-X main.version=${VERSION}" -o ${@} main.go

# CLEAN
# ==============================================================================
PHONY+=clean
clean:
	rm --force --recursive $(shell pwd)/getpsrc*

# GOLANGCI-LINT
# ==============================================================================
PHONY+=golangci-lint
golangci-lint:
	golangci-lint run --concurrency=$(shell nproc)

# GOSEC
# ==============================================================================
PHONY+=gosec
gosec:
	gosec $(shell pwd)/...

# CONTAINER-IMAGE
# ==============================================================================
PHONY+=container-image/build
container-image/build:
	${CONTAINER_RUNTIME} build \
		--build-arg BASE_IMAGE=${BASE_IMAGE_FULLY_QUALIFIED} \
		--build-arg BUILD_IMAGE=${BUILD_IMAGE_FULLY_QUALIFIED} \
		--build-arg GOPRIVATE=$(shell go env GOPRIVATE) \
		--build-arg GOPROXY=$(shell go env GOPROXY) \
		--build-arg GONOPROXY=$(shell go env GONOPROXY) \
		--build-arg GONOSUMDB=$(shell go env GONOSUMDB) \
		--build-arg GOSUMDB=$(shell go env GOSUMDB) \
		--build-arg VERSION=${VERSION} \
		--file ./Dockerfile \
		--no-cache \
		--tag ${CONTAINER_IMAGE_UNQUALIFIED} \
		--tag ${CONTAINER_IMAGE_FULLY_QUALIFIED} \
		.

PHONY+=container-image/push
container-image/push: container-image/build
	${CONTAINER_RUNTIME} push ${CONTAINER_IMAGE_FULLY_QUALIFIED}

# CONTAINER STEPS - EXECUTABLE
# ==============================================================================
PHONY+=container-run/all
container-run/all:
	$(MAKE) container-run COMMAND=${@:container-run/%=%}

PHONY+=${EXECUTABLE_TARGETS:%=container-run/%}
${EXECUTABLE_TARGETS:%=container-run/%}:
	$(MAKE) container-run COMMAND=${@:container-run/%=%}

# CONTAINER STEPS - CLEAN
# ==============================================================================
PHONY+=container-run/clean
container-run/clean:
	$(MAKE) container-run COMMAND=${@:container-run/%=%}

# GENERAL CONTAINER COMMAND
# ==============================================================================
PHONY+=container-run
container-run:
	${CONTAINER_RUNTIME} run \
		--env CONTAINER_IMAGE_VERSION=${CONTAINER_IMAGE_VERSION} \
		--env GONOPROXY=$(shell go env GONOPROXY) \
		--env GONOSUMDB=$(shell go env GONOSUMDB) \
		--env GOPRIVATE=$(shell go env GOPRIVATE) \
		--env GOPROXY=$(shell go env GOPROXY) \
		--env GOSUMDB=$(shell go env GOSUMDB) \
		--env VERSION=${VERSION} \
		--net=host \
		--rm \
		--volume /tmp:/tmp \
		--volume ${HOME}/go:/root/go \
		--volume $(shell pwd):/workspace \
		--workdir /workspace \
			${BUILD_IMAGE_FULLY_QUALIFIED} \
				make ${COMMAND}

# PHONY
# ==============================================================================
# Declare the contents of the PHONY variable as phony. We keep that information
# in a variable so we can use it in if_changed.
.PHONY: ${PHONY}
