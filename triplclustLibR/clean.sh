#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PKG_SRC="${SCRIPT_DIR}/src"
BUILD_DIR="${PROJECT_ROOT}/build"

INCLUDE_RPACKAGE=false
PACKAGE_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --include_rpackage)
      INCLUDE_RPACKAGE=true
      ;;
    --package-only)
      PACKAGE_ONLY=true
      ;;
    *)
      echo "Unknown option: $arg"
      exit 1
      ;;
  esac
done

clean_package() {
  find "${PKG_SRC}" -type f \
    \( -name '*.o' -o -name 'RcppExports.*' -o -name 'triplclust*.so' \
       -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' -o -name '*.inc' \) \
    ! -name 'rcpp_interface.cpp' -delete
  find "${PKG_SRC}" -type d -empty -not -path "${PKG_SRC}" -delete
}

clean_package

if [[ "${PACKAGE_ONLY}" == false ]]; then
  [ -z "${BUILD_DIR:-}" ] && {
    echo "BUILD_DIR is empty – abort"
    exit 1
  }

  if [[ "${INCLUDE_RPACKAGE}" == true ]]; then
    find "${BUILD_DIR}" -mindepth 1 -exec rm -rf {} +
  else
    find "${BUILD_DIR}" -mindepth 1 \
      ! -path "${BUILD_DIR}/rpackage" \
      ! -path "${BUILD_DIR}/rpackage/*" \
      -exec rm -rf {} +
  fi
fi