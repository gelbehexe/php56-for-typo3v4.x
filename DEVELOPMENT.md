# Development

This document describes how to build and test the `php56-for-typo3v4.x` image locally.

## Building the image

You can use the provided `Makefile` to build the image:

```bash
# Standard build
make build

# Build with extra arguments (e.g. no-cache)
make build ARGS="--no-cache"
```

Alternatively, use the local build script:

```bash
./build/build-local.sh --no-cache
```

## Running tests

An automated test suite is included to verify the PHP environment and dependencies:

```bash
# Run tests via Makefile
make test

# Run build and test in one command
make all
```

The tests are located in `tests/test.sh`.
