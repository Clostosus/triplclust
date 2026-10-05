.prepare_export_data <- function(points, labels) {
  if (is.list(labels)) {
    if (length(labels) != nrow(points)) {
      stop("labels must have one element per point", call. = FALSE)
    }
    point_clusters <- lapply(labels, function(ids) {
      if (!is.numeric(ids) || anyNA(ids) || any(!is.finite(ids)) ||
          any(ids != floor(ids)) || any(ids < 1L)) {
        stop("each point's cluster IDs must be positive integers",
             call. = FALSE)
      }
      unique(as.integer(ids))
    })
    special_overlap_ids <- integer(0)
  } else if (is.numeric(labels) || is.integer(labels) ||
             is.character(labels)) {
    point_labels <- suppressWarnings(as.integer(labels))
    if (length(point_labels) != nrow(points) || anyNA(point_labels) ||
        any(point_labels < -2L)) {
      stop("labels must have one valid cluster label per point",
           call. = FALSE)
    }
    special_overlap_ids <- which(point_labels == -2L)
    point_clusters <- lapply(point_labels, function(id) {
      if (id < 0L) integer(0) else id + 1L
    })
  } else {
    stop("labels must be a point-indexed list or a per-point label vector",
         call. = FALSE)
  }

  cluster_ids <- sort(unique(unlist(point_clusters, use.names = FALSE)))
  clusters <- lapply(cluster_ids, function(cluster_id) {
    which(vapply(point_clusters, function(ids) cluster_id %in% ids,
                 logical(1)))
  })
  names(clusters) <- as.character(cluster_ids)
  overlap_ids <- sort(unique(c(
    special_overlap_ids,
    which(lengths(point_clusters) > 1L)
  )))
  unassigned_ids <- setdiff(which(lengths(point_clusters) == 0L),
                            special_overlap_ids)

  list(
    clusters = clusters,
    point_clusters = point_clusters,
    cluster_ids = cluster_ids,
    overlap_ids = overlap_ids,
    unassigned_ids = unassigned_ids
  )
}

.plot_colour_hex <- function(cluster_index) {
  idx <- as.integer(cluster_index)
  red <- ((idx * 23L) %% 19L) / 18
  green <- ((idx * 23L) %% 7L) / 6
  blue <- ((idx * 23L) %% 3L) / 2
  tolower(grDevices::rgb(red, green, blue))
}
