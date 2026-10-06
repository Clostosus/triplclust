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
  status <- attr(output, "status")
  if (!is.null(status)) stopifnot(status == 0L)
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

unlink(c(points_file, stderr_file))
