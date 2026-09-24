//
// triplclust.hpp
//     Library interface for the TriplClust algorithm.
//

#ifndef TRIPLCLUST_HPP
#define TRIPLCLUST_HPP

#include <cstddef>

#include "cluster.h"
#include "pointcloud.h"

struct TriplClustParameters {
  double r;
  size_t k;
  size_t n;
  double a;
  double s;
  double t;
  bool tauto;
  double dmax;
  bool is_dmax;
  Linkage linkage;
  size_t m;
  int verbose;

  TriplClustParameters()
      : r(0.0),
        k(0),
        n(0),
        a(0.0),
        s(0.0),
        t(0.0),
        tauto(false),
        dmax(0.0),
        is_dmax(false),
        linkage(SINGLE),
        m(0),
        verbose(0) {}
};

cluster_group triplclust(const PointCloud &cloud,
                         const TriplClustParameters &parameters);

#endif