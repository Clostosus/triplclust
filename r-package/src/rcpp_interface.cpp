#include <Rcpp.h>
#include "pointcloud.h"
#include "triplclust.h"

constexpr int NOISE_LABEL = 0;

// [[Rcpp::export]]
Rcpp::List triplclust_rcpp(
    Rcpp::NumericMatrix points,
    double r, bool r_dnn,
    int k, int n, double a,
    double s, bool s_dnn,
    double t, bool tauto,
    double dmax, bool dmax_dnn, bool is_dmax,
    std::string linkage, int m, int verbose, bool ordered) {
  PointCloud cloud;
  cloud.setOrdered(ordered);
  const int n_points = points.nrow();
  for (int row = 0; row < n_points; ++row) {
    cloud.push_back(Point(points(row, 0), points(row, 1), points(row, 2)));
  }

  TriplClustParameters params;
  params.r = r;
  params.r_dnn = r_dnn;
  params.k = k;
  params.n = n;
  params.a = a;
  params.s = s;
  params.s_dnn = s_dnn;
  params.t = t;
  params.tauto = tauto;
  params.dmax = dmax;
  params.dmax_dnn = dmax_dnn;
  params.is_dmax = is_dmax;
  params.linkage = (linkage == "single") ? SINGLE :
                   (linkage == "complete") ? COMPLETE : AVERAGE;
  params.m = m;
  params.verbose = verbose;

  const cluster_group result = triplclust(cloud, params);

  std::vector<std::vector<int>> point_to_clusters(n_points);

  for (size_t cluster = 0; cluster < result.size(); ++cluster) {
    for (size_t idx = 0; idx < result[cluster].size(); ++idx) {
      int point_idx = static_cast<int>(result[cluster][idx]);
      point_to_clusters[point_idx].push_back(static_cast<int>(cluster));
    }
  }

  Rcpp::List cluster_ids_list(n_points);
  for (int i = 0; i < n_points; ++i) {
    if (point_to_clusters[i].empty()) {
      cluster_ids_list[i] = NOISE_LABEL;
    } else {
      Rcpp::IntegerVector ids(point_to_clusters[i].size());
      for (size_t j = 0; j < point_to_clusters[i].size(); ++j) {
        ids[j] = point_to_clusters[i][j];
      }
      cluster_ids_list[i] = ids;
    }
  }

  return cluster_ids_list;
}