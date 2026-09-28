#!/usr/bin/env Rscript
# -------------------------------------------------------------
#  build.R – invoked from ./build.sh
#  • Generates RcppExports.* files
#  • Installs the R package
# -------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)

# If no argument is given, assume the script lives next to the package folder
if (length(args) == 0) {
  pkg_dir <- file.path(dirname(normalizePath(sys.frame(1)$ofile)), "..")
} else {
  pkg_dir <- args[1]
}

if (!file.exists(pkg_dir)) {
  stop("Package directory does not exist: ", pkg_dir)
}

setwd(pkg_dir)

#  Install Rcpp if it is not already present
if (!requireNamespace("Rcpp", quietly = TRUE)) {
  install.packages("Rcpp", repos = "https://cloud.r-project.org")
}
if (!requireNamespace("pkgbuild", quietly = TRUE)) {
  install.packages("pkgbuild", repos = "https://cloud.r-project.org")
}

#  Generate the Rcpp registration files
Rcpp::compileAttributes()

#  Build the package
dir.create("../build/rpackage", recursive = TRUE, showWarnings = FALSE)
pkgbuild::build(
  path = ".",
  dest_path = "../build/rpackage/triplclust.R"
)