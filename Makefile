# VERSION
VERSION?=$(shell git describe --abbrev=0)+hash.$(shell git rev-parse --short HEAD)

# CONTAINER_RUNTIME
CONTAINER_RUNTIME?=$(shell which podman)

# CONTAINER_IMAGE
CONTAINER_IMAGE_REGISTRY_HOST?=git.cryptic.systems
CONTAINER_IMAGE_REPOSITORY=volker.raschek/getpsrc
CONTAINER_IMAGE_VERSION?=latest
CONTAINER_IMAGE_FULLY_QUALIFIED=${CONTAINER_IMAGE_REGISTRY_HOST}/${CONTAINER_IMAGE_REPOSITORY}:${CONTAINER_IMAGE_VERSION}

# EXECUTABLES
# ==============================================================================
EXECUTABLE_TARGETS=getpsrc

PHONY=all
all: clean ${EXECUTABLE_TARGETS}

getpsrc:
	go build -tags netgo -ldflags "-X main.version=${VERSION}" -o ${@} main.go


# CLEAN
# ==============================================================================
PHONY+=clean
clean:
	rm -f -r $(shell pwd)/getpsrc*

# TESTS
# ==============================================================================
PHONY+=test/unit
test/unit:
	CGO_ENABLED=0 \
	GOPROXY=$(shell go env GOPROXY) \
		go test -v -p 1 -coverprofile=coverage.txt -covermode=count -timeout 1200s ./...

PHONY+=test/coverage
test/coverage: test/unit
	CGO_ENABLED=0 \
	GOPROXY=$(shell go env GOPROXY) \
		go tool cover -html=coverage.txt

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
		--build-arg VERSION=${VERSION} \
		--file ./Dockerfile \
		--no-cache \
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
		--env VERSION=${VERSION} \
		--net=host \
		--rm \
		--volume /tmp:/tmp \
		--volume "${HOME}/go:/root/go" \
		--volume "$(shell pwd):$(shell pwd)" \
		--workdir "$(shell pwd)" \
			${BUILD_IMAGE_FULLY_QUALIFIED} \
				make ${COMMAND}

# PHONY
# ==============================================================================
# Declare the contents of the PHONY variable as phony. We keep that information
# in a variable so we can use it in if_changed.
.PHONY: ${PHONY}
