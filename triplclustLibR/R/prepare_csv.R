#' Convert cluster assignments to CSV text
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param labels Either a list of integer vectors returned by `triplclust()` or
#'   a per-point integer vector.
#' @return A character string containing CSV-formatted coordinates and labels,
#'   with zero-based cluster IDs, `-1` for noise, and `-2` for overlaps.
#' @export
prepare_csv <- function(points, labels) {
  if (!is.matrix(points) || !is.numeric(points) || ncol(points) != 3L) {
    stop(
      "points must be a numeric matrix with exactly three columns",
      call. = FALSE
    )
  }

  export_data <- .prepare_export_data(points, labels)
  point_labels <- rep("-1", nrow(points))
  if (length(export_data$point_clusters) > 0L) {
    point_labels[as.integer(names(export_data$point_clusters))] <-
      vapply(export_data$point_clusters, function(cluster_ids) {
        paste(cluster_ids - 1L, collapse = ";")
      }, character(1))
  }
  point_labels[export_data$overlap_ids] <- "-2"

  rows <- paste(formatC(points[, 1], digits = 6, format = "f"),
    formatC(points[, 2], digits = 6, format = "f"),
    formatC(points[, 3], digits = 6, format = "f"),
    point_labels,
    sep = ","
  )

  paste(c(
    "# Comment: curveID -1 represents noise; -2 represents overlap",
    "# x, y, z, curveID",
    rows
  ), collapse = "\n")
}
