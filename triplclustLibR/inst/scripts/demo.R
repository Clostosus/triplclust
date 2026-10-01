#!/usr/bin/env Rscript
# -------------------------------------------------------------
#  Demo for the 'triplclust' package.
#  This script is installed with the package (inst/scripts/demo.R)
#  and can be run after the package is installed:
#
#        Rscript -e "system('demo.R', intern = FALSE)"
#
#  It loads a tiny synthetic point cloud, runs the algorithm
#  with the default parameters and prints a short summary.
# -------------------------------------------------------------

# Load the library ------------------------------------------------
library(triplclust)

# -----------------------------------------------------------------
#  1) Construct a minimal point cloud --------------------------------
# -----------------------------------------------------------------
#   The package expects a numeric matrix with 3 columns (x, y, z).
#   Here we build three collinear points as a trivial example.
pts <- matrix(c(
  0, 0, 0,
  1, 0, 0,
  2, 0, 0
), ncol = 3, byrow = TRUE)

cat("Input point cloud (", nrow(pts), " points):\n", sep = "")
print(pts)

# -----------------------------------------------------------------
#  2) Run the algorithm with the *default* parameters ---------------
# -----------------------------------------------------------------
#   The R wrapper (`triplclust`) accepts numeric and dNN-scaled distances.
#   that the C++ binary does.  We only set a few to keep the demo short.
res <- triplclust(
  points = pts,
  r      = 2.0,          # smoothing radius (default = 2 * dNN)
  k      = 19,           # neighbours for triplet creation
  n      = 2,            # number of best triplets to keep
  a      = 0.03,         # max angle
  s      = 0.33,         # scaling factor for clustering
  tauto   = TRUE,        # let the algorithm choose the best cut height
  linkage = "single",    # linkage method
  m      = 5,            # minimum number of triplets per cluster
  verbose = 0
)

cat("\n--- Result ------------------------------------------------\n")
cat("Number of clusters found :", length(res), "\n")
if (length(res) > 0) {
  cat("Size of each cluster       :", sapply(res, length), "\n")
}
cat("--- End of demo -------------------------------------------\n")