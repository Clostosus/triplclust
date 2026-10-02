library(triplclust)

data("attpc", package = "triplclust", envir = environment())
points_file <- tempfile()
stderr_file <- tempfile()
write.table(attpc, file = points_file, row.names = FALSE, col.names = FALSE)

script <- system.file("scripts", "use_triplclust.R", package = "triplclust")
stopifnot(nzchar(script))

run_export <- function(arguments) {
  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    args = c(shQuote(script), shQuote(points_file), arguments),
    stdout = TRUE,
    stderr = stderr_file
  )
  stopifnot(is.null(attr(output, "status")) || attr(output, "status") == 0L)
  output
}

csv <- run_export(character())
stopifnot(
  startsWith(csv[1], "# Comment:"),
  length(csv) == nrow(attpc) + 2L
)

gnuplot <- run_export("-gnuplot")
stopifnot(
  any(startsWith(gnuplot, "splot ")),
  tail(gnuplot, 1) == "pause mouse keypress"
)

overlap_points <- matrix(seq_len(15), ncol = 3)
overlap_script <- strsplit(
  prepare_plot(overlap_points, list(c(1L, 2L, 3L), c(2L, 4L), c(3L, 5L))),
  "\n",
  fixed = TRUE
)[[1]]
stopifnot(
  grepl("lc 'black' title 'overlap'", overlap_script, fixed = TRUE),
  sum(grepl("title 'overlap'", overlap_script, fixed = TRUE)) == 1L,
  all(c("2.00000000 7.00000000 12.00000000", "3.00000000 8.00000000 13.00000000") %in%
    overlap_script)
)
overlap_csv <- strsplit(
  prepare_csv(overlap_points, list(c(1L, 2L, 3L), c(2L, 4L), c(3L, 5L))),
  "\n",
  fixed = TRUE
)[[1]]
stopifnot(
  overlap_csv[1] ==
    "# Comment: curveID -1 represents noise; -2 represents overlap",
  grepl("^2\\.000000,7\\.000000,12\\.000000,-2$", overlap_csv[4]),
  grepl("^3\\.000000,8\\.000000,13\\.000000,-2$", overlap_csv[5])
)

unlink(c(points_file, stderr_file))
