#include <Rcpp.h>
#include "triplclust.hpp"
#include "pointcloud.h"

using namespace Rcpp;

// -----------------------------------------------------------------
//  Internal implementation (no Rcpp export, no default args)
// -----------------------------------------------------------------
static Rcpp::IntegerVector triplclust_impl(
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
    
    // convert Rcpp::NumericMatrix to PointCloud
    PointCloud cloud;
    for (int i = 0; i < points.nrow(); i++) {
        cloud.push_back(Point(points(i, 0), points(i, 1), points(i, 2)));
    }

    // set params and use defaults of triplclust.hpp
    TriplClustParameters params;
    params.r = r;
    params.k = k;
    params.n = n;
    params.a = a;
    params.s = s;
    params.t = t;
    params.tauto = tauto;
    params.dmax = dmax;
    params.is_dmax = is_dmax;
    params.linkage = (linkage == "single") ? SINGLE :
                   (linkage == "complete") ? COMPLETE : AVERAGE;
    params.m = m;
    params.verbose = verbose;

    cluster_group result = triplclust(cloud, params);

    Rcpp::IntegerVector labels(points.nrow(), 0);
    for (size_t cluster_index = 0; cluster_index < result.size();
         ++cluster_index) {
        for (size_t point_index : result[cluster_index]) {
            if (point_index < static_cast<size_t>(labels.size())) {
                labels[point_index] = static_cast<int>(cluster_index + 1);
            }
        }
    }
    return labels;
}

// -----------------------------------------------------------------
//  Exported wrapper – **the only function Rcpp sees**
// -----------------------------------------------------------------
//[[Rcpp::export]]
Rcpp::IntegerVector triplclust_rcpp(
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

    // Forward everything to the internal implementation.
    // No overloads here → Rcpp can generate a single, unambiguous entry.
    return triplclust_impl(points, r, k, n, a, s, t,
                           tauto, dmax, is_dmax, linkage, m, verbose);
}