library(triplclust)

data("attpc", package = "triplclust", envir = environment())
stopifnot(is.data.frame(attpc), nrow(attpc) == 121L,
          identical(names(attpc), c("x", "y", "z")))

points <- as.matrix(attpc)
default_result <- triplclust(points)
explicit_result <- triplclust(points, r = "2dNN", s = "0.33dNN", dmax = "none")
automatic_result <- triplclust(points, t = "auto")
fixed_result <- triplclust(points, t = 0)
stopifnot(length(default_result) > 0L,
          identical(default_result, explicit_result),
          identical(default_result, automatic_result),
          identical(fixed_result, triplclust(points, t = 0)))

invalid_points <- matrix(as.numeric(1:4), ncol = 2)
rejected <- tryCatch({
  triplclust(invalid_points)
  FALSE
}, error = function(error) TRUE)
stopifnot(rejected)

invalid_distance <- tryCatch({
  triplclust(points, r = "1.5dNNx")
  FALSE
}, error = function(error) TRUE)
stopifnot(invalid_distance)