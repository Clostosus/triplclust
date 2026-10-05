library(triplclust)

data("attpc", package = "triplclust", envir = environment())
stopifnot(is.data.frame(attpc), nrow(attpc) == 121L,
          identical(names(attpc), c("x", "y", "z")))

points <- as.matrix(attpc)
default_result <- triplclust(points)
explicit_result <- triplclust(points, r = "2dNN", s = "0.33dNN", dmax = "none")
automatic_result <- triplclust(points, t = "auto")
fixed_result <- triplclust(points, t = 0)
stopifnot(length(default_result) == nrow(points),
          all(vapply(default_result, is.integer, logical(1))),
          all(vapply(default_result, function(ids) {
            all(ids > 0L)
          }, logical(1))),
          identical(default_result, explicit_result),
          identical(default_result, automatic_result),
          identical(fixed_result, triplclust(points, t = 0)))

example_memberships <- list(c(1L, 2L), integer(), 2L)
example_points <- matrix(as.numeric(1:9), ncol = 3)
csv <- prepare_csv(example_points, example_memberships)
stopifnot(grepl("1.000000,4.000000,7.000000,-2", csv, fixed = TRUE),
          grepl("2.000000,5.000000,8.000000,-1", csv, fixed = TRUE),
          grepl("3.000000,6.000000,9.000000,1", csv, fixed = TRUE))
plot <- prepare_plot(example_points, example_memberships)
stopifnot(grepl("title 'curve 1'", plot, fixed = TRUE),
          grepl("title 'overlap'", plot, fixed = TRUE))

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