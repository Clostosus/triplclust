#!/usr/bin/env Rscript
# -------------------------------------------------------------
#  Test script for the R package `triplclust`
# -------------------------------------------------------------
# Usage:
#   Rscript use_triplclust.R <input_file> [-gnuplot] > output.csv
#
#   <input_file> : whitespace‑separated file with three columns (x y z)
#   -gnuplot      : also emit a tiny Gnuplot script on stdout
# -------------------------------------------------------------

# ---------- 1. Parse command‑line arguments ----------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("Usage: Rscript use_triplclust.R <input_file> [-gnuplot]")
}
infile  <- args[1]
gnuplot <- any(args[-1] %in% "-gnuplot")   # TRUE if “-gnuplot” present

# ---------- 2. Load the installed package ----------
# The package was installed by ./build.sh into your personal library, e.g.
#   ~/R/x86_64-pc-linux-gnu-library/4.6
# No lib.loc is needed – just attach it.
suppressPackageStartupMessages(library(triplclustLibR))

# ---------- 3. Read the point cloud ----------
pts <- read.table(infile, header = FALSE, sep = "", stringsAsFactors = FALSE)
if (ncol(pts) != 3) {
  stop("Input file must contain exactly three columns (x y z).")
}
pts_mat <- as.matrix(pts)   # numeric matrix (n × 3)

# ---------- 4. Call the C++ function (defaults are taken from the header) ----------
clusters <- triplclust_rcpp(pts_mat)   # <- exported Rcpp function

# ---------- 5. Build the output data frame ----------
out_df <- data.frame(
  x       = pts_mat[, 1],
  y       = pts_mat[, 2],
  z       = pts_mat[, 3],
  cluster = clusters
)

# ---------- 6. Write CSV to stdout (you can redirect it) ----------
write.csv(out_df, row.names = FALSE, file = stdout())

# ---------- 7. Optional Gnuplot script -----------------------------------------
if (gnuplot) {
  # Write a *temporary* CSV file that Gnuplot can read.
  tmp_csv <- tempfile(fileext = ".csv")
  write.csv(out_df, row.names = FALSE, file = tmp_csv)

  cat(sprintf("
set terminal wxt enhanced
set title 'TriplClust – %s'
set xlabel 'X'
set ylabel 'Y'
set zlabel 'Z'
splot '%s' using 1:2:3:4 with points pointtype 7 pointsize 1 notitle
", basename(infile), tmp_csv))
}