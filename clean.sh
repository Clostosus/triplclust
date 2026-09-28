#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_SRC="${PROJECT_ROOT}/triplclustLibR/src"
BUILD_DIR="${PROJECT_ROOT}/build"

clean_package() {
  find "${PKG_SRC}" -type f \
    \( -name '*.o' -o -name 'RcppExports.*' -o -name 'triplclust*.so' \
       -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name '*.inc' \) \
    ! -name 'rcpp_interface.cpp' -delete
  find "${PKG_SRC}" -type d -empty -not -path "${PKG_SRC}" -delete
}

clean_package

if [[ "${1:-}" != "--package-only" ]]; then
  rm -rf "${BUILD_DIR}"
fi