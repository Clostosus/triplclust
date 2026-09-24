#!/bin/sh
set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BUILD_DIR="$PROJECT_ROOT/build"

cmake -S "$PROJECT_ROOT" -B "$BUILD_DIR" "$@"
cmake --build "$BUILD_DIR"
