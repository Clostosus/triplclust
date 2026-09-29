#' Cluster a 3D point cloud
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param r Smoothing radius, as a number or a dNN-scaled string; defaults to
#'   `2dNN`.
#' @param k Number of nearest neighbors used to generate candidate triplets.
#' @param n Minimum number of neighbors used by triplet generation.
#' @param a Collinearity tolerance for candidate triplets.
#' @param s Distance scale for hierarchical clustering; defaults to `0.33dNN`.
#' @param t Fixed clustering threshold when `tauto` is `FALSE`.
#' @param tauto Whether to choose the clustering threshold automatically.
#' @param dmax Optional maximum gap for splitting clusters; accepts a number,
#'   a dNN-scaled string, or `"none"`.
#' @param linkage Linkage method: `"single"`, `"complete"`, or `"average"`.
#' @param m Minimum cluster size retained by pruning.
#' @param verbose Verbosity level for diagnostic output.
#' @usage triplclust_rcpp(points, r = NULL, k = 19L, n = 2L, a = 0.03,
#'   s = NULL, t = 0, tauto = TRUE, dmax = NULL, linkage = "single",
#'   m = 5L, verbose = 0L)
#' @return A list of integer vectors containing the 1-based row indices for
#'   each cluster. A point may occur in more than one cluster.
#' @name triplclust_rcpp
NULL