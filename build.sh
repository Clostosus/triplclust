#!/usr/bin/env bash
# -------------------------------------------------------------
#  build.sh – builds the C++ binary (CMake) **and** the R package
# -------------------------------------------------------------
set -euo pipefail

# -----------------------------------------------------------------
#  Paths
# -----------------------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
PKG_DIR="${PROJECT_ROOT}/triplclustLibR"
R_PKG_DIR="${PROJECT_ROOT}/triplclustLibR"
PKG_SRC="${PKG_DIR}/src"

# -----------------------------------------------------------------
#  1) Build the standalone C++ binary with CMake
# -----------------------------------------------------------------
echo "=== Building C++ binary (CMake) ==="
cmake -S "${PROJECT_ROOT}" -B "${BUILD_DIR}" "$@"
cmake --build "${BUILD_DIR}"
echo "=== C++ binary built ==="

# -----------------------------------------------------------------
#  2) Copy the algorithm sources and headers into the R package.
#     R CMD INSTALL builds from a temporary source tree, so the
#     package must contain all files needed by the shared library.
# -----------------------------------------------------------------
echo "=== Copying all core C++ sources (temporary) ==="
mkdir -p "${PKG_SRC}"
"${PROJECT_ROOT}/clean.sh" --package-only
find "${PROJECT_ROOT}/src" -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
  ! -name 'main.cpp' ! -name 'option.cpp' | while read -r srcfile; do
  base="$(basename "${srcfile}")"
  if [[ "${srcfile}" == *.cpp && "${base}" != fastcluster_*dm.cpp ]]; then
    # normale Quellen flach ins Paket -> werden von R kompiliert
    cp "${srcfile}" "${PKG_SRC}/${base}"
  else
    # Header und die per #include eingebundenen dm-Dateien mit Unterordner
    relpath="${srcfile#${PROJECT_ROOT}/src/}"
    mkdir -p "${PKG_SRC}/$(dirname "${relpath}")"
    cp "${srcfile}" "${PKG_SRC}/${relpath}"
  fi
done

echo "=== Sources copied ==="

# -----------------------------------------------------------------
#  3) Build the R package (this will compile the temporary sources as well)
# -----------------------------------------------------------------
echo "=== Building R package ==="
Rscript "${PKG_DIR}/build.R" "${PKG_DIR}"
echo "=== R package built ==="

# -----------------------------------------------------------------
#  4) **Clean up** – delete the temporary copies we just added
# -----------------------------------------------------------------
echo "=== Removing temporary C++ sources from the package ==="
"${PROJECT_ROOT}/clean.sh" --package-only
echo "=== Cleanup finished ==="

echo "Build completed!"