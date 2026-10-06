.prepare_export_data <- function(points, labels) {
  if (is.list(labels)) {
    if (length(labels) != nrow(points)) {
      stop("labels must have one element per point", call. = FALSE)
    }
    point_clusters <- lapply(labels, function(ids) {
      if (!is.numeric(ids)) {
        stop("each point's cluster IDs must be numeric", call. = FALSE)
      }
      if (anyNA(ids)) {
        stop("each point's cluster IDs must not contain missing values",
             call. = FALSE)
      }
      if (any(!is.finite(ids))) {
        stop("each point's cluster IDs must be finite", call. = FALSE)
      }
      if (any(ids != floor(ids))) {
        stop("each point's cluster IDs must be integers", call. = FALSE)
      }
      if (any(ids < 1L)) {
        stop("each point's cluster IDs must be positive", call. = FALSE)
      }
      unique(as.integer(ids))
    })
  } else {
    if (!is.numeric(labels)) {
      if (!is.character(labels)) {
        stop("labels must be a point-indexed list or a per-point label vector",
             call. = FALSE)
      }
    }
    point_labels <- suppressWarnings(as.integer(labels))
    if (length(point_labels) != nrow(points)) {
      stop("labels must have one value per point", call. = FALSE)
    }
    if (anyNA(point_labels)) {
      stop("labels must contain valid integer cluster labels",
           call. = FALSE)
    }
    if (any(point_labels < -1L)) {
      stop("labels must be -1 for noise or non-negative cluster IDs",
           call. = FALSE)
    }
    point_clusters <- lapply(point_labels, function(id) {
      if (id == -1L) integer(0) else id + 1L
    })
  }

  cluster_ids <- sort(unique(unlist(point_clusters, use.names = FALSE)))
  clusters <- lapply(cluster_ids, function(cluster_id) {
    which(vapply(point_clusters, function(ids) cluster_id %in% ids,
                 logical(1)))
  })
  names(clusters) <- as.character(cluster_ids)
  overlap_ids <- which(lengths(point_clusters) > 1L)
  unassigned_ids <- which(lengths(point_clusters) == 0L)

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
