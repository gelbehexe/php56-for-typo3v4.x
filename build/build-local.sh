#!/bin/bash

# Ensure we are in the project root
cd "$(dirname "$0")/.." || exit

# Export Buildkit progress preference
export BUILDKIT_PROGRESS=plain

# Forward all script arguments to make's ARGS variable
make build ARGS="$*"
