library(triplclust)

data("attpc", package = "triplclust", envir = environment())
stopifnot(is.data.frame(attpc), nrow(attpc) == 121L,
          identical(names(attpc), c("x", "y", "z")))

invalid_points <- matrix(as.numeric(1:4), ncol = 2)
rejected <- tryCatch({
  triplclust_rcpp(invalid_points)
  FALSE
}, error = function(error) TRUE)
stopifnot(rejected)