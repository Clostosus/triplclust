.prepare_plot_labels <- function(points, labels) {
  if (is.list(labels)) {
    cluster_list <- lapply(labels, as.integer)
    if (length(cluster_list) == 0L) {
      return(list())
    }
    bad <- vapply(cluster_list, function(idx) {
      length(idx) > 0L && any(idx < 1L | idx > nrow(points))
    }, logical(1))
    if (any(bad)) {
      stop("cluster indices are out of range", call. = FALSE)
    }
    return(cluster_list)
  }

  if (is.numeric(labels) || is.integer(labels) || is.character(labels)) {
    labels <- as.integer(labels)
    if (length(labels) != nrow(points)) {
      stop("labels must have one value per point", call. = FALSE)
    }
    if (any(is.na(labels))) labels[is.na(labels)] <- 0L
    return(split(seq_len(nrow(points)), labels))
  }

  stop("labels must be a list of integer vectors or a per-point label vector",
       call. = FALSE)
}

.prepare_export_data <- function(points, labels) {
  clusters <- lapply(.prepare_plot_labels(points, labels), unique)
  point_clusters <- split(
    rep.int(seq_along(clusters), lengths(clusters)),
    unlist(clusters, use.names = FALSE)
  )
  cluster_counts <- sapply(point_clusters, length)
  overlap_ids <- as.integer(names(cluster_counts)[cluster_counts > 1L])
  assigned_ids <- as.integer(names(point_clusters))

  list(
    clusters = clusters,
    point_clusters = point_clusters,
    overlap_ids = overlap_ids,
    unassigned_ids = setdiff(seq_len(nrow(points)), assigned_ids)
  )
}

.plot_colour_hex <- function(cluster_index) {
  idx <- as.integer(cluster_index)
  red <- ((idx * 23L) %% 19L) / 18
  green <- ((idx * 23L) %% 7L) / 6
  blue <- ((idx * 23L) %% 3L) / 2
  tolower(grDevices::rgb(red, green, blue))
}
