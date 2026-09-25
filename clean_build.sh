#!/usr/bin/env bash
# -------------------------------------------------------------
# clean-and-build.sh
#   • removes all artefacts created by the R package (object files,
#     generated RcppExports files, the .so library)
#   • deletes the CMake build directory
#   • rebuilds the C++ binary (via CMake) and the R package
#   • checks that the package loads and that the exported function
#     triplclust_rcpp is available
# -------------------------------------------------------------

set -euo pipefail      # abort on any error, treat unset vars as error

# -------------------------------------------------------------
# 1) CONFIGURATION – adapt only these two lines if you move things
# -------------------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="${PROJECT_ROOT}/tripclustLibR"   # <-- change if you renamed the folder
# -------------------------------------------------------------

# derived paths
BUILD_DIR="${PROJECT_ROOT}/build"
RPKG_SRC="${PKG_DIR}/src"
PKG_SRC="${PKG_DIR}/src"

# -----------------------------------------------------------------
# Helper functions for pretty output
# -----------------------------------------------------------------
hline() { printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; }
msg()   { echo -e "\e[1;34m[INFO]\e[0m  $*"; }
err()   { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

# -----------------------------------------------------------------
# 2) Clean the R‑package artefacts
# -----------------------------------------------------------------
msg "Cleaning all generated artefacts ..."
find "${PKG_SRC}" -type f $-name '*.o' -o -name 'RcppExports.*' -o -name 'triplclust*.so'$ -delete
# Remove temporary .cpp copies (keep the original rcpp_interface.cpp)
find "${PKG_SRC}" -type f -name '*.cpp' ! -name 'rcpp_interface.cpp' -delete
# Remove empty directories (but not the top‑level src/)
find "${PKG_SRC}" -type d -empty -not -path "${PKG_SRC}" -delete

# -----------------------------------------------------------------
# 3) Remove the CMake build directory
# -----------------------------------------------------------------
msg "Removing CMake build directory ..."
if [[ -d "${BUILD_DIR}" ]]; then
    rm -rf "${BUILD_DIR}"
    msg "Deleted ${BUILD_DIR}"
else
    msg "No build directory found – nothing to delete"
fi

# -----------------------------------------------------------------
# 4) Re‑build everything (uses your existing top‑level script)
# -----------------------------------------------------------------
msg "Running top‑level build script ..."
if "${PROJECT_ROOT}/build.sh"; then
    msg "✅  build.sh completed without errors"
else
    err "❌  build.sh reported a failure – aborting"
    exit 1
fi

# -----------------------------------------------------------------
# 5) Verify that the R package can be loaded and the function exists
# -----------------------------------------------------------------
msg "Loading R package and checking exported symbol ..."
Rscript - <<'R_EOF'
pkg <- "triplclust"                     # <-- package name as in DESCRIPTION/NAMESPACE
if (!requireNamespace(pkg, quietly = TRUE)) {
  quit(status = 1, message = paste0("Package ", pkg, " not installed"))
}
library(pkg, character.only = TRUE)

# Check that the exported function is present
if (!("triplclust_rcpp" %in% ls(paste0("package:", pkg)))) {
  quit(status = 1,
       message = "Exported function triplclust_rcpp not found in the package namespace")
}
quit(status = 0)
R_EOF
R_STATUS=$?
if [[ ${R_STATUS} -ne 0 ]]; then
    err "❌  R could not load the package or the function is missing"
    exit 1
else
    msg "✅  R package loads correctly and triplclust_rcpp is available"
fi

hline
msg "All done – you can now run your demo script, e.g.:"
msg "  ${PKG_DIR}/tests/use_triplclust.R test.dat > test.csv"
msg "  ${PKG_DIR}/tests/use_triplclust.R test.dat -gnuplot | gnuplot -persist"
hline
exit 0