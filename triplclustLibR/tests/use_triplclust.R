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
suppressPackageStartupMessages(library(triplclust))

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

# ---------- 6. Write CSV or a Gnuplot script (similar to output.cpp) ----------
# Colors like in compute_cluster_colour() in output.cpp; Cluster k has index k-1
cluster_colour <- function(label) {
  idx <- label - 1
  r <- floor(((idx * 23) %% 19) / 18 * 255)
  g <- floor(((idx * 23) %% 7)  / 6  * 255)
  b <- floor(((idx * 23) %% 3)  / 2  * 255)
  as.integer(r * 65536 + g * 256 + b)
}

if (!gnuplot) {
  write.csv(out_df, row.names = FALSE, file = stdout())
} else {
  # Value range like find_min_max_point(): when min == max, +-1 is taken
  axis_range <- function(v) {
    lo <- min(v); hi <- max(v)
    if (hi > lo) c(lo, hi) else c(lo - 1, hi + 1)
  }
  for (ax in c("x", "y", "z")) {
    rg <- axis_range(out_df[[ax]])
    cat(sprintf("set %srange [%.6f:%.6f]\n", ax, rg[1], rg[2]))
  }

  # Punktblock einer Serie (endet mit "e")
  points_block <- function(df) {
    paste0(paste(sprintf("%.6f %.6f %.6f", df$x, df$y, df$z), collapse = "\n"),
           "\ne\n")
  }

  series <- character(0)
  blocks <- character(0)

  # Noise first (label 0), red
  noise <- out_df$cluster == 0
  if (any(noise)) {
    series <- c(series, "'-' with points lc 'red' title 'noise'")
    blocks <- c(blocks, points_block(out_df[noise, ]))
  }
  # then each cluster with its own color and title 'curve N'
  for (lab in sort(unique(out_df$cluster[!noise]))) {
    series <- c(series, sprintf("'-' with points lc '#%06x' title 'curve %d'",
                                cluster_colour(lab), lab))
    blocks <- c(blocks, points_block(out_df[out_df$cluster == lab, ]))
  }

  cat("splot ", paste(series, collapse = ", "), "\n", sep = "")
  cat(blocks, sep = "")
  cat("pause mouse keypress\n")
}