#!/usr/bin/env Rscript
# -------------------------------------------------------------
#  Test script for the R package `triplclust`
# -------------------------------------------------------------
# Usage:
#   Rscript use_triplclust.R <input_file> [-gnuplot] [--profile=<name>] > output.csv
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
profile <- if (length(profile_arg) == 1) sub("^--profile=", "", profile_arg) else "defaults"

# ---------- 2. Load the installed package ----------
# The package was installed by ./triplclustLibR/build.sh from the repository root, e.g.
#   ~/R/x86_64-pc-linux-gnu-library/4.6
# No lib.loc is needed – just attach it.
suppressPackageStartupMessages(library(triplclust))

# ---------- 3. Read the point cloud ----------
pts <- read.table(infile, header = FALSE, sep = "", stringsAsFactors = FALSE)
if (ncol(pts) != 3) {
  stop("Input file must contain exactly three columns (x y z).")
}
pts_mat <- as.matrix(pts)   # numeric matrix (n × 3)

# ---------- 4. Call the C++ function with the selected parameters ----------
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
clusters <- do.call(triplclust_rcpp, c(list(points = pts_mat), profile_params))
n <- nrow(pts_mat)

# Per point: the clusters it belongs to (integer(0) = noise, >1 = overlap)
ids <- split(rep(seq_along(clusters), lengths(clusters)),
             factor(unlist(clusters), levels = seq_len(n)))

# ---------- 5. Output as in output.cpp ----------
# Cluster ids as in the C++ output are 0-based
cluster_colour <- function(cluster_index) {
  r <- floor(((cluster_index * 23) %% 19) / 18 * 255)
  g <- floor(((cluster_index * 23) %% 7)  / 6  * 255)
  b <- floor(((cluster_index * 23) %% 3)  / 2  * 255)
  as.integer(r * 65536 + g * 256 + b)
}

if (!gnuplot) {
  # like clusters_to_csv(): -1 = noise, multiple labels separated by ';'
  lab <- vapply(ids, function(v)
    if (length(v) == 0) "-1" else paste(v - 1L, collapse = ";"), character(1))
  cat("# Comment: curveID -1 represents noise\n# x, y, z, curveID\n")
  writeLines(sprintf("%.6f,%.6f,%.6f,%s",
                     pts_mat[, 1], pts_mat[, 2], pts_mat[, 3], lab))
} else {
  # Overlap points get their own group per distinct set of clusters (like the
  # "vertex" clusters of add_clusters(..., gnuplot = true)) and are removed
  # from their original clusters.
  multi  <- which(lengths(ids) > 1)
  groups <- lapply(clusters, function(p) p[!p %in% multi])
  if (length(multi) > 0) {
    keys   <- vapply(ids[multi], paste, character(1), collapse = ";")
    groups <- c(groups,
                unname(split(multi, factor(keys, levels = unique(keys)))))
  }

  axis_range <- function(v) {
    lo <- min(v); hi <- max(v)
    if (hi > lo) c(lo, hi) else c(lo - 1, hi + 1)
  }
  for (i in 1:3) {
    rg <- axis_range(pts_mat[, i])
    cat(sprintf("set %srange [%.6f:%.6f]\n", c("x", "y", "z")[i], rg[1], rg[2]))
  }

  points_block <- function(idx) {
    paste0(paste(sprintf("%.6f %.6f %.6f",
                         pts_mat[idx, 1], pts_mat[idx, 2], pts_mat[idx, 3]),
                 collapse = "\n"), "\ne\n")
  }

  series <- character(0)
  blocks <- character(0)

  noise <- which(lengths(ids) == 0)
  if (length(noise) > 0) {
    series <- c(series, "'-' with points lc 'red' title 'noise'")
    blocks <- c(blocks, points_block(noise))
  }

  for (i in seq_along(groups)) {
    pts <- groups[[i]]
    if (length(pts) == 0) next          # colour index still counts, as in C++
    cid <- ids[[pts[1]]] - 1L
    title <- if (length(cid) > 1) paste0("overlap ", paste(cid, collapse = ";"))
             else paste0("curve ", cid)
    series <- c(series, sprintf("'-' with points lc '#%06x' title '%s'",
                                cluster_colour(i - 1), title))
    blocks <- c(blocks, points_block(pts))
  }

  cat("splot ", paste(series, collapse = ", "), "\n", sep = "")
  cat(blocks, sep = "")
  cat("pause mouse keypress\n")
}