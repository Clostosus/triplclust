#!/usr/bin/env bash
# Creates the CRAN source tarball in <project>/build/cran/.
# All work happens in a temporary directory; the repository stays untouched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUT_DIR="${PROJECT_ROOT}/build/cran"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
PKG="${WORK}/triplclust"
mkdir -p "${PKG}" "${OUT_DIR}"

rsync -a "${SCRIPT_DIR}/" "${PKG}/" \
  --exclude makecrandist.sh --exclude build.sh --exclude clean.sh \
  --exclude clean_build.sh --exclude verify.sh --exclude build.R \
  --exclude 'src/*.o' --exclude 'src/*.so' --exclude 'src/RcppExports.*'

# Preserve the full license in the tarball while using CRAN's short LICENSE format.
mkdir -p "${PKG}/inst"
cp "${SCRIPT_DIR}/LICENSE" "${PKG}/inst/COPYRIGHTS"
cp "${SCRIPT_DIR}/lic_cran" "${PKG}/LICENSE"

# Copy shared C++ sources into the temporary package tree only.
find "${PROJECT_ROOT}/src" -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) \
  ! -name 'main.cpp' ! -name 'option.cpp' | while read -r f; do
  base="$(basename "$f")"
  if [[ "$f" == *.cpp && "$base" != fastcluster_*dm.cpp ]]; then
    cp "$f" "${PKG}/src/${base}"
  elif [[ "$base" == triplclust.hpp ]]; then
    cp "$f" "${PKG}/src/triplclust.h"
  else
    rel="${f#${PROJECT_ROOT}/src/}"
    mkdir -p "${PKG}/src/$(dirname "$rel")"
    cp "$f" "${PKG}/src/${rel}"
  fi
done

cp "${PROJECT_ROOT}/src/hclust/LICENSE" "${PKG}/src/hclust/LICENSE"
cp "${PROJECT_ROOT}/src/kdtree/LICENSE" "${PKG}/src/kdtree/LICENSE"

# Route C++ console output through Rcpp in this disposable package copy.
while IFS= read -r -d '' source; do
  if grep -Eq 'std::(cout|cerr)' "$source"; then
    {
      printf '#include <Rcpp.h>\n'
      sed -e 's/std::cout/Rcpp::Rcout/g' \
          -e 's/std::cerr/Rcpp::Rcout/g' \
          -e 's/"triplclust\.hpp"/"triplclust.h"/g' "$source"
    } > "${source}.tmp"
    mv "${source}.tmp" "$source"
  else
    sed 's/"triplclust\.hpp"/"triplclust.h"/g' "$source" > "${source}.tmp"
    mv "${source}.tmp" "$source"
  fi
done < <(find "${PKG}/src" -type f -name '*.cpp' -print0)

# Remove only upstream warning-suppression pragmas in the disposable source copy.
while IFS= read -r -d '' source; do
  sed '/^[[:space:]]*#pragma GCC diagnostic /d' "$source" > "${source}.tmp"
  mv "${source}.tmp" "$source"
done < <(find "${PKG}/src" -type f -name 'fastcluster_*dm.cpp' -print0)

Rscript -e "Rcpp::compileAttributes('${PKG}'); roxygen2::roxygenise('${PKG}', roclets = c('collate','rd'))"
( cd "${WORK}" && R CMD build triplclust )
mv "${WORK}"/triplclust_*.tar.gz "${OUT_DIR}/"
echo "Tarball: ${OUT_DIR}/"