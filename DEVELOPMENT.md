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

## Admin User Customization

The `entrypoint.sh` supports the following variables for the initial admin user:

- `TYPO3_INITIAL_ADMIN_USERNAME`: Defaults to `admin`.
- `TYPO3_INITIAL_ADMIN_UID`: Defaults to `1`. 
  - Set to `auto` to let MySQL handle the UID (auto-increment).
  - If a numeric UID is provided, the script verifies it is not already taken before creation.

## CI/CD Setup

To enable automated builds and pushes to Docker Hub, you need to configure the following secrets/variables in your CI environment (GitHub Secrets or GitLab CI/CD Variables):

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: A Personal Access Token (PAT) from Docker Hub.

### Creating a Docker Hub Token

1. Go to **Account Settings** > **Security** > **Personal Access Tokens** on Docker Hub.
2. Generate a new token with **Read & Write** permissions.
3. Use this token as the value for `DOCKERHUB_TOKEN`.
