#include <Rcpp.h>
#include <cerrno>
#include <cmath>
#include <cstdlib>
#include <string>
#include "dnn.h"
#include "triplclust.h"
#include "pointcloud.h"

using namespace Rcpp;

struct DistanceValue {
    double value;
    bool dnn;
    bool enabled;
};

static DistanceValue parse_distance(
    Rcpp::RObject input,
    const char* name,
    double default_value,
    bool default_dnn,
    bool default_enabled = true,
    bool allow_none = false) {
    if (input.isNULL()) {
        return {default_value, default_dnn, default_enabled};
    }

    if (TYPEOF(input) == REALSXP || TYPEOF(input) == INTSXP) {
        if (Rf_length(input) != 1) {
            Rcpp::stop("%s must have length one", name);
        }
        const double value = Rcpp::as<double>(input);
        if (!std::isfinite(value)) {
            Rcpp::stop("%s must be finite", name);
        }
        return {value, false, true};
    }

    if (TYPEOF(input) != STRSXP || Rf_length(input) != 1) {
        Rcpp::stop("%s must be a number or a dNN-suffixed string", name);
    }
    const std::string specification = Rcpp::as<std::string>(input);
    if (allow_none && specification == "none") {
        return {0.0, false, false};
    }

    errno = 0;
    char* end = nullptr;
    const double value = std::strtod(specification.c_str(), &end);
    if (end == specification.c_str() || errno == ERANGE || !std::isfinite(value)) {
        Rcpp::stop("%s must start with a finite number", name);
    }
    const std::string suffix(end);
    if (!suffix.empty() && suffix != "dNN" && suffix != "dnn") {
        Rcpp::stop("%s suffix must be dNN", name);
    }
    return {value, !suffix.empty(), true};
}

//  Internal implementation (no Rcpp export, no default args)
static Rcpp::List triplclust_impl(
    const Rcpp::NumericMatrix& points,
    Rcpp::RObject r_input, int k, int n,
    double a, Rcpp::RObject s_input,
    double t, bool tauto,
    Rcpp::RObject dmax_input,
    const std::string& linkage,
    int m, int verbose) {

    // # input validation
    if (points.ncol() != 3) {
        stop("points must be a numeric matrix with exactly three columns");
    }
    if (k <= 0) {
    Rcpp::stop("k must be a positive integer");
    }
    if (n <= 0) {
        Rcpp::stop("n must be a positive integer");
    }
    if (a <= 0.0 || a >= 1.0) {
        Rcpp::stop("a must be in (0, 1)");
    }
    if (m < 1) {
        Rcpp::stop("m (minimum triplets per cluster) must be at least 1");
    }
    if (linkage != "single" && linkage != "complete" && linkage != "average") {
        Rcpp::stop("linkage must be 'single', 'complete', or 'average'");
    }
    
    PointCloud cloud;
    for (int i = 0; i < points.nrow(); i++) {
        cloud.push_back(Point(points(i, 0), points(i, 1), points(i, 2)));
    }

    const DistanceValue r = parse_distance(r_input, "r", 2.0, true);
    const DistanceValue s = parse_distance(s_input, "s", 0.33, true);
    const DistanceValue dmax = parse_distance(dmax_input, "dmax", 0.0, false,
                                              false, true);
    const bool needs_dnn = r.dnn || s.dnn || (dmax.enabled && dmax.dnn);
    double dnn = 1.0;
    if (needs_dnn) {
        dnn = std::sqrt(first_quartile(cloud));
        if (dnn == 0.0) {
            Rcpp::stop("dnn computed as zero. Remove duplicate points.");
        }
    }

    TriplClustParameters params;
    params.r = r.value * (r.dnn ? dnn : 1.0);
    params.k = k;
    params.n = n;
    params.a = a;
    params.s = s.value * (s.dnn ? dnn : 1.0);
    params.t = t;
    params.tauto = tauto;
    params.dmax = dmax.value * (dmax.dnn ? dnn : 1.0);
    params.is_dmax = dmax.enabled;
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
    Rcpp::RObject r = R_NilValue,
    int    k       = 19,
    int    n       = 2,
    double a       = 0.03,
    Rcpp::RObject s = R_NilValue,
    double t       = 0.0,
    bool   tauto   = true,
    Rcpp::RObject dmax = R_NilValue,
    std::string linkage = "single",
    int    m       = 5,
    int    verbose = 0) {

    return triplclust_impl(points, r, k, n, a, s, t,
                           tauto, dmax, linkage, m, verbose);
}