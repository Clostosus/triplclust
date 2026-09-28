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
PKG_DIR="${PROJECT_ROOT}/triplclustLibR"   # <-- change if you renamed the folder
# -------------------------------------------------------------

# -----------------------------------------------------------------
# Helper functions for pretty output
# -----------------------------------------------------------------
hline() { printf '%*s\n' 80 '' | tr ' ' -; }
msg()   { echo -e "\e[1;34m[INFO]\e[0m  $*"; }
err()   { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; }

# -----------------------------------------------------------------
# 2) Clean generated artefacts and the CMake build directory
# -----------------------------------------------------------------
msg "Cleaning generated artefacts ..."
"${PROJECT_ROOT}/clean.sh"

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