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
#  2) **Temporarily copy** all project C++ source files into the
#     R package's src/ directory.
#     After the R package is installed we will delete them again.
# -----------------------------------------------------------------
echo "=== Copying all core C++ sources (temporary) ==="
mkdir -p "${PKG_SRC}"
# Find every .cpp file in the project src/ tree
find "${PROJECT_ROOT}/src" -type f -name '*.cpp' | while read -r srcfile; do
  relpath="${srcfile#${PROJECT_ROOT}/src/}"           # e.g. "kdtree/kdtree.cpp"
  targetdir="${PKG_SRC}/$(dirname "${relpath}")"
  mkdir -p "${targetdir}"
  cp "${srcfile}" "${targetdir}/"
done
# Also copy the wrapper file (if it lives somewhere else; in our case it already
# is in the package src/, so this step is harmless)
if [[ -f "${PROJECT_ROOT}/triplclustLibR/src/rcpp_interface.cpp" ]]; then
  cp "${PROJECT_ROOT}/triplclustLibR/src/rcpp_interface.cpp" "${PKG_SRC}/"
fi
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
# Delete every .cpp file we copied **except** the original wrapper
find "${PKG_SRC}" -type f -name '*.cpp' ! -name 'rcpp_interface.cpp' -delete
# Remove any empty sub‑directories that may remain
find "${PKG_SRC}" -type d -empty -not -path "${PKG_SRC}" -delete
echo "=== Cleanup finished ==="

echo "Build completed successfully!"