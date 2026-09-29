library(triplclust)

invalid_points <- matrix(as.numeric(1:4), ncol = 2)
rejected <- tryCatch({
  triplclust_rcpp(invalid_points)
  FALSE
}, error = function(error) TRUE)
stopifnot(rejected)