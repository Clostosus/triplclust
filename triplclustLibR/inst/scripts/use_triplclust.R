#!/usr/bin/env Rscript
# -------------------------------------------------------------
#  Test script for the R package `triplclust`
# -------------------------------------------------------------
# Usage:
# Rscript use_triplclust.R <input_file> [-gnuplot] <name> > output.csv
#
#   <input_file> : whitespace‑separated file with three columns (x y z)
#   -gnuplot      : also emit a tiny Gnuplot script on stdout
#   <name>        : defaults, dnn_scale, absolute_distance, or dnn_gap
# -------------------------------------------------------------

# ---------- 1. Parse command‑line arguments ----------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Usage: Rscript use_triplclust.R <input_file> [-gnuplot]")
}
infile  <- args[1]
gnuplot <- any(args[-1] %in% "-gnuplot")   # TRUE if “-gnuplot” present
profile_arg <- grep("^--profile=", args, value = TRUE)
if (length(profile_arg) > 1) {
  stop("Only one --profile may be specified.")
}
profile <- if (length(profile_arg) == 1)
  sub("^--profile=", "", profile_arg) else "defaults"

# ---------- 2. Load the installed package ----------
# Load the package only when it is not already attached.
if (!"triplclust" %in% loadedNamespaces()) {
  # `requireNamespace` loads the namespace without attaching the package;
  # we then attach it with `library(..., character.only = TRUE)` 
  # to get the exported symbols.
  if (!requireNamespace("triplclust", quietly = TRUE)) {
    stop("Package 'triplclust' is not installed – run ./build.sh first.")
  }
  suppressPackageStartupMessages(
    library("triplclust", character.only = TRUE, quietly = TRUE)
  )
}

# ---------- 3. Read the point cloud ----------
pts <- read.table(infile, header = FALSE, sep = "", stringsAsFactors = FALSE)
if (ncol(pts) != 3) {
  stop("Input file must contain exactly three columns (x y z).")
}
pts_mat <- as.matrix(pts)   # numeric matrix (n × 3)

# ---------- 4. Call the R wrapper with the selected parameters ----------
profile_params <- switch(profile,
  defaults = list(),
  dnn_scale = list(r = "1.5dNN", s = "0.25dNN", k = 13L, n = 3L, a = 0.05,
                   m = 4L, linkage = "complete"),
  absolute_distance = list(r = 1.5, s = 0.25, dmax = 2.5,
                           k = 13L, n = 3L, a = 0.05, m = 4L,
                           linkage = "average"),
  dnn_gap = list(dmax = "1.5dNN"),
  stop("Unknown verification profile: ", profile)
)

# ---- measure ONLY the triplclust call --------------------------------
t0 <- proc.time()
clusters <- do.call(triplclust,
                    c(list(points = pts_mat), profile_params))
elapsed_ms <- (proc.time() - t0)[["elapsed"]] * 1000
cat(sprintf("# R-call %.1f ms\n", elapsed_ms), file = stderr())
# ------------------------------------------------------------------------

if (gnuplot) {
  cat(prepare_plot(pts_mat, clusters), "\n", sep = "")
} else {
  cat(prepare_csv(pts_mat, clusters), "\n", sep = "")
}