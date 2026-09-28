#include <Rcpp.h>
#include <cmath>
#include "dnn.h"
#include "triplclust.hpp"
#include "pointcloud.h"

using namespace Rcpp;

//  Internal implementation (no Rcpp export, no default args)
static Rcpp::List triplclust_impl(
    const Rcpp::NumericMatrix& points,
    double r, int k, int n,
    double a, double s,
    double t, bool tauto,
    double dmax, bool is_dmax,
    const std::string& linkage,
    int m, int verbose) {

    if (points.ncol() != 3) {
        stop("points must be a numeric matrix with exactly three columns");
    }
    
    PointCloud cloud;
    for (int i = 0; i < points.nrow(); i++) {
        cloud.push_back(Point(points(i, 0), points(i, 1), points(i, 2)));
    }

    double dnn = std::sqrt(first_quartile(cloud));
    if (dnn == 0.0) {
        Rcpp::stop("dnn computed as zero. Remove duplicate points.");
    }

    // set params and use defaults of triplclust.hpp
    TriplClustParameters params;
    params.r = r * dnn;
    params.k = k;
    params.n = n;
    params.a = a;
    params.s = s * dnn;
    params.t = t;
    params.tauto = tauto;
    params.dmax = dmax;
    params.is_dmax = is_dmax;
    params.linkage = (linkage == "single") ? SINGLE :
                   (linkage == "complete") ? COMPLETE : AVERAGE;
    params.m = m;
    params.verbose = verbose;

    cluster_group result = triplclust(cloud, params);

    // One element per cluster: the 1-based row indices of its points.
    // A point may appear in several clusters (overlap).
    Rcpp::List clusters(result.size());
    for (size_t c = 0; c < result.size(); ++c) {
        Rcpp::IntegerVector idx(result[c].size());
        for (size_t j = 0; j < result[c].size(); ++j) {
            idx[j] = static_cast<int>(result[c][j]) + 1;
        }
        clusters[c] = idx;
    }
    return clusters;
}

//  Exported wrapper – **the only function Rcpp sees**
//[[Rcpp::export]]
Rcpp::List triplclust_rcpp(
    Rcpp::NumericMatrix points,
    double r       = 2.0,
    int    k       = 19,
    int    n       = 2,
    double a       = 0.03,
    double s       = 0.33,
    double t       = 0.0,
    bool   tauto   = true,
    double dmax    = 0.0,
    bool   is_dmax = false,
    std::string linkage = "single",
    int    m       = 5,
    int    verbose = 0) {

    return triplclust_impl(points, r, k, n, a, s, t,
                           tauto, dmax, is_dmax, linkage, m, verbose);
}