# triplclust

R package providing an interface to the **TriplClust** algorithm for 3D point-cloud clustering.

## System requirements (Debian / Ubuntu)

To build the package from source you need the following libraries:

```bash
sudo apt update
sudo apt install -y libharfbuzz-dev libfribidi-dev libuv1-dev
R -e "install.packages(c('devtools','roxygen2'), repos='https://cloud.r-project.org')"
R -e "devtools::document()"
```

## installation
The R interface is built and installed from the repository root with:

```bash
     ./triplclustLibR/build.sh
```

This installs the `triplclust` package and exports `triplclust_rcpp()`.

## Basic usage
The function accepts an `n x 3` numeric matrix and returns one integer cluster
label per input point; `0` denotes a point that was not assigned to a
cluster.

```R
    library(triplclustLibR)

    ## generate a small random point cloud (n x 3 matrix)
    pts <- matrix(rnorm(30), ncol = 3)

    ## run the clustering function
    cls <- triplclust_rcpp(pts)

    head(cls)   # shows the first few cluster labels (0 = unassigned)
```

Distance arguments follow the C++ program syntax: numeric values are absolute
distances, while strings with a `dNN` suffix are relative to the characteristic
point spacing. The defaults are `r = "2dNN"`, `s = "0.33dNN"`, and
`dmax = "none"`. For example, use `r = 2.0` for an absolute radius or
`dmax = "1.5dNN"` to split clusters at a relative gap threshold.

For a complete clean rebuild and a package check afterwards, run from the repository root:

```bash
     ./triplclustLibR/clean_build.sh
     ./triplclustLibR/verify.sh
```