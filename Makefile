.PHONY: build test all

# Default values for Docker Hub
DOCKER_USER ?= gelbehexe
REPO_NAME ?= php56-for-typo3v4.x

IMAGE_NAME = $(DOCKER_USER)/$(REPO_NAME)
ALT_NAME = testimage

all: build test

build:
	docker build $(ARGS) -t $(IMAGE_NAME) -t $(ALT_NAME) .

test:
	./tests/test.sh $(IMAGE_NAME)
