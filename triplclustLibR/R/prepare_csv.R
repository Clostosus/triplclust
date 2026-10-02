#' Convert cluster assignments to CSV text
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param labels Either a list of integer vectors returned by `triplclust()` or
#'   a per-point integer vector.
#' @return A character string containing CSV-formatted coordinates and labels,
#'   with zero-based cluster IDs and `-1` for noise.
#' @export
prepare_csv <- function(points, labels) {
  if (!is.matrix(points) || !is.numeric(points) || ncol(points) != 3L) {
    stop(
      "points must be a numeric matrix with exactly three columns",
      call. = FALSE
    )
  }

  cluster_list <- .prepare_plot_labels(points, labels)
  point_to_cluster <- split(
    rep.int(
      seq_along(cluster_list) - 1L,
      lengths(cluster_list)
    ),
    unlist(cluster_list, use.names = FALSE)
  )
  point_labels <- rep("-1", nrow(points))
  if (length(point_to_cluster) > 0L) {
    point_labels[as.integer(names(point_to_cluster))] <-
      vapply(
        point_to_cluster,
        function(idx) paste(idx, collapse = ";"),
        character(1)
      )
  }

  rows <- paste(formatC(points[, 1], digits = 6, format = "f"),
    formatC(points[, 2], digits = 6, format = "f"),
    formatC(points[, 3], digits = 6, format = "f"),
    point_labels,
    sep = ","
  )

  paste(c(
    "# Comment: curveID -1 represents noise",
    "# x, y, z, curveID",
    rows
  ), collapse = "\n")
}
