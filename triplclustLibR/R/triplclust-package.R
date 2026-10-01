#' @title triplclust – R interface to the TriplClust algorithm
#' @description
#' An R package for using the TriplClust algorithm for detecting and separating
#' curves in 3-D point clouds.
#' @name triplclust
#' @docType package
#' @keywords internal
#' @useDynLib triplclust, .registration = TRUE
#' @importFrom Rcpp evalCpp
"_PACKAGE"

utils::globalVariables("_triplclust_triplclust_rcpp")