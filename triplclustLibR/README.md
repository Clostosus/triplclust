R package
---------

The R interface is built and installed with the top-level build script:

    $ ./build.sh

This installs the `triplclust` package and exports `triplclust_rcpp()`. The
function accepts an `n x 3` numeric matrix and returns one integer cluster
label per input point; `0` denotes a point that was not assigned to a
cluster.

For a complete clean rebuild and package check, run from the tripclust directory:

    $ ./clean_build.sh
