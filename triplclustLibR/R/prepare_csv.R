#' Convert cluster assignments to CSV text
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param labels Either the point-indexed list returned by `triplclust()` or a
#'   per-point integer vector (`-1` for noise, non-negative IDs for clusters).
#' @return A character string containing CSV-formatted coordinates and labels,
#'   with zero-based cluster IDs, `-1` for noise, and semicolon-separated IDs
#'   when a point belongs to multiple clusters.
#' @export
prepare_csv <- function(points, labels) {
  if (!is.matrix(points)) {
    stop("points must be a matrix", call. = FALSE)
  }
  if (!is.numeric(points)) {
    stop("points must be numeric", call. = FALSE)
  }
  if (ncol(points) != 3L) {
    stop("points must have exactly three columns", call. = FALSE)
  }

  export_data <- .prepare_export_data(points, labels)
  point_labels <- rep("-1", nrow(points))
  for (point in seq_len(nrow(points))) {
    cluster_ids <- export_data$point_clusters[[point]]
    if (length(cluster_ids) > 0L) {
      point_labels[[point]] <- paste(cluster_ids - 1L, collapse = ";")
    }
  }
  rows <- paste(formatC(points[, 1], digits = 6, format = "f"),
    formatC(points[, 2], digits = 6, format = "f"),
    formatC(points[, 3], digits = 6, format = "f"),
    point_labels,
    sep = ","
  )

  paste(c(
    "# Comment: curveID -1 represents noise; multiple IDs are separated by semicolons",
    "# x, y, z, curveID",
    rows
  ), collapse = "\n")
}
