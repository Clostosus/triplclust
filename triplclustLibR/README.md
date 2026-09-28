R package
---------

The R interface is built and installed from the repository root with:

    $ ./triplclustLibR/build.sh

This installs the `triplclust` package and exports `triplclust_rcpp()`. The
function accepts an `n x 3` numeric matrix and returns one integer cluster
label per input point; `0` denotes a point that was not assigned to a
cluster.

Distance arguments follow the C++ program syntax: numeric values are absolute
distances, while strings with a `dNN` suffix are relative to the characteristic
point spacing. The defaults are `r = "2dNN"`, `s = "0.33dNN"`, and
`dmax = "none"`. For example, use `r = 2.0` for an absolute radius or
`dmax = "1.5dNN"` to split clusters at a relative gap threshold.

For a complete clean rebuild and package check, run from the repository root:

    $ ./triplclustLibR/clean_build.sh
