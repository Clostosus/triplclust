# triplclust

R package providing an interface to the **TriplClust** algorithm for 3D point-cloud clustering.

## Build
Using `makecrandist.sh` generates a tar.gz file containing the package.

## Installation
To install the package in R without CRAN, you need the tarball(tar.gz) of the package.

```
install.packages("pathtofile/triplclust_1.0.0.tar.gz",
                 repos = NULL, type = "source")
```

## Verification
In case you cloned the repository, use `verify.sh`.
For a less extensive verification use the R Scripts from `inst/scripts` that use the triplclust R-function.

## Basic usage
The function accepts an `n x 3` numeric matrix and returns one integer cluster
label per input point; `0` denotes a point that was not assigned to a
cluster.

```R
    library(triplclustLibR)

    ## generate a small random point cloud (n x 3 matrix)
    pts <- matrix(rnorm(30), ncol = 3)

    ## run the clustering function
     cls <- triplclust(pts)

    head(cls)   # shows the first few cluster labels (0 = unassigned)
```