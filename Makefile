.PHONY: build test all

IMAGE_NAME = gelbehexe/php56-for-typo3v4.x
ALT_NAME = testimage

all: build test

build:
	docker build $(ARGS) -t $(IMAGE_NAME) -t $(ALT_NAME) .

test:
	./tests/test.sh $(IMAGE_NAME)