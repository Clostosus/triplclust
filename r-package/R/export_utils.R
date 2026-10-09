#' Convert cluster assignments to CSV text
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param labels A list of integer vectors from \code{triplclust()} (per-point
#'   cluster IDs, 0-based, 0 = noise, multiple = overlap).
#' @return A character string containing CSV-formatted coordinates and labels,
#'   with 0-based cluster IDs, \code{0} for noise, and semicolon-separated
#'   IDs for overlaps.
#' @export
prepare_csv <- function(points, labels) {
  point_labels <- vapply(labels, function(ids) {
    if (length(ids) == 1L && ids[1] == 0L) "0" else paste(ids, collapse = ";")
  }, character(1))

  rows <- paste(formatC(points[, 1], digits = 6, format = "f"),
    formatC(points[, 2], digits = 6, format = "f"),
    formatC(points[, 3], digits = 6, format = "f"),
    point_labels,
    sep = ","
  )

  paste(c(
    "# Comment: curveID 0 represents noise; semicolon-separated IDs for overlaps",
    "# x, y, z, curveID",
    rows
  ), collapse = "\n")
}

#' Convert cluster assignments to gnuplot command text
#'
#' @param points Numeric matrix with exactly three columns (x, y, z).
#' @param labels A list of integer vectors from \code{triplclust()} (per-point
#'   cluster IDs, 0-based, 0 = noise, multiple = overlap).
#' @return A character string containing a gnuplot script.
#' @export
prepare_plot <- function(points, labels) {
  n_points <- nrow(points)

  noise_ids <- integer(0)
  overlap_ids <- integer(0)
  clusters <- list()

  # Convert points[cluster_ids[]] -> clusters[point_ids[]] for gnuplot
  for (i in seq_len(n_points)) {
    ids <- labels[[i]]
    if (length(ids) == 1L) {
      cid <- ids[1]
      if (cid == 0L) {
        noise_ids <- c(noise_ids, i)
      } else if (cid >= 0L) {
        cluster_idx <- cid + 1L
        if (cluster_idx > length(clusters)) length(clusters) <- cluster_idx
        if (is.null(clusters[[cluster_idx]]))
          clusters[[cluster_idx]] <- integer(0)
        clusters[[cluster_idx]] <- c(clusters[[cluster_idx]], i)
      }
      next
    }
    if (length(ids) > 1L) {
      overlap_ids <- c(overlap_ids, i)
    }
    for (cid in ids) {
      if (cid < 0L) next
      cluster_idx <- cid + 1L
      if (cluster_idx > length(clusters)) length(clusters) <- cluster_idx
      if (is.null(clusters[[cluster_idx]])) clusters[[cluster_idx]] <- integer(0)
      clusters[[cluster_idx]] <- c(clusters[[cluster_idx]], i)
    }
  }

  clusters <- clusters[!vapply(clusters, is.null, logical(1))]
  clusters <- lapply(clusters, unique)

  cluster_indices <- lapply(clusters,
                            function(indices) setdiff(indices, overlap_ids))
  cluster_numbers <- which(lengths(cluster_indices) > 0L)
  cluster_indices <- cluster_indices[cluster_numbers]

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

  noise_series <- if (length(noise_ids) > 0L) {
    "'-' with points lc 'red' title 'noise'"
  } else {
    character(0)
  }
  noise_blocks <- if (length(noise_ids) > 0L) {
    points_block(noise_ids)
  } else {
    character(0)
  }

  cluster_colours <- .plot_colour_hex(cluster_numbers)
  cluster_series <- if (length(cluster_numbers) > 0L) {
    paste0(
      "'-' with points lc '", cluster_colours,
      "' title 'curve ", cluster_numbers, "'"
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

.plot_colour_hex <- function(cluster_index) {
  idx <- as.integer(cluster_index)
  red <- ((idx * 23L) %% 19L) / 18
  green <- ((idx * 23L) %% 7L) / 6
  blue <- ((idx * 23L) %% 3L) / 2
  tolower(grDevices::rgb(red, green, blue))
}
