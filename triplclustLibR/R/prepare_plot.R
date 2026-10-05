#' Convert cluster assignments to gnuplot script text
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param labels Either the point-indexed list returned by
#'   \code{triplclust()} or a per-point integer vector. In a per-point vector,
#'   `-1` marks noise and `-2` marks overlap.
#' @return A character string containing a gnuplot script.
#' @export
prepare_plot <- function(points, labels) {
  if (!is.matrix(points) || !is.numeric(points) || ncol(points) != 3L) {
    stop(
      "points must be a numeric matrix with exactly three columns",
      call. = FALSE
    )
  }

  export_data <- .prepare_export_data(points, labels)
  cluster_indices <- lapply(export_data$clusters, function(indices) {
    setdiff(indices, export_data$overlap_ids)
  })
  overlap_ids <- export_data$overlap_ids
  non_clustered <- export_data$unassigned_ids
  keep_clusters <- lengths(cluster_indices) > 0L
  cluster_numbers <- export_data$cluster_ids[keep_clusters]
  cluster_indices <- cluster_indices[keep_clusters]

  axis_names <- c("x", "y", "z")
  axis_min <- apply(points, 2, min)
  axis_max <- apply(points, 2, max)
  axis_lower <- ifelse(axis_max > axis_min, axis_min, axis_min - 1)
  axis_upper <- ifelse(axis_max > axis_min, axis_max, axis_max + 1)
  ranges <- paste0(
    "set ", axis_names, "range [",
    formatC(axis_lower, digits = 8, format = "f"), ":",
    formatC(axis_upper, digits = 8, format = "f"), "]"
  )

  formatted_points <- paste(formatC(points[, 1], digits = 8, format = "f"),
    formatC(points[, 2], digits = 8, format = "f"),
    formatC(points[, 3], digits = 8, format = "f"),
    sep = " "
  )
  points_block <- function(indices) {
    c(paste(formatted_points[indices], collapse = "\n"), "e")
  }

  noise_series <- if (length(non_clustered) > 0L) {
    "'-' with points lc 'red' title 'noise'"
  } else {
    character(0)
  }
  noise_blocks <- if (length(non_clustered) > 0L) {
    points_block(non_clustered)
  } else {
    character(0)
  }

  cluster_colours <- .plot_colour_hex(cluster_numbers)
  cluster_series <- if (length(cluster_numbers) > 0L) {
    paste0(
      "'-' with points lc '", cluster_colours,
      "' title 'curve ", cluster_numbers - 1L, "'"
    )
  } else {
    character(0)
  }
  cluster_blocks <- unlist(
    lapply(cluster_indices, points_block),
    use.names = FALSE
  )

  overlap_series <- if (length(overlap_ids) > 0L) {
    "'-' with points lc 'black' title 'overlap'"
  } else {
    character(0)
  }
  overlap_blocks <- if (length(overlap_ids) > 0L) {
    points_block(overlap_ids)
  } else {
    character(0)
  }

  series <- c(noise_series, cluster_series, overlap_series)
  blocks <- c(noise_blocks, cluster_blocks, overlap_blocks)

  script <- c(
    ranges,
    paste0("splot ", paste(series, collapse = ", ")),
    blocks,
    "pause mouse keypress"
  )
  paste(script, collapse = "\n")
}
