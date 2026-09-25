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
  // Radius for point smoothing [2dNN]
  // (can be numeric or multiple of dNN)
  double r;
  // Number of neighbours in triplet creation [19]
  size_t k;
  // Number of the best triplets to use [2]
  size_t n;
  // Maximum value for the angle between the triplet branches [0.03]
  double a;
  // Scaling factor for clustering [0.33dNN]
  // (can be numeric or multiple of dNN)
  double s;
  // Best cluster distance [0.0]
  double t;
  // Flag indicating if t is set to 'auto' [true]
  bool tauto;
  // Maximum gap width within a triplet [none]
  // (can be numeric, multiple of dNN or 'none')
  double dmax;
  // Flag indicating if dmax was set [false]
  bool is_dmax;
  // Linkage method for clustering [single]
  // (can be 'single', 'complete', 'average')
  Linkage linkage;
  // Minimum number of triplets for a cluster [5]
  size_t m;
  // Verbosity level [0]
  int verbose;

  TriplClustParameters()
      : r(2.0),k(19),n(2), a(0.03),s(0.33), 
        t(0.0),tauto(true),
        dmax(0.0), is_dmax(false),
        linkage(SINGLE), m(5), verbose(0) {}
};

/*
 * Function for the TriplClust algorithm.
 @param cloud The input point cloud to be clustered.
 @param parameters The parameters for the TriplClust algorithm. 
 @returns a cluster_group containing the clusters found in the input point cloud.
 */
cluster_group triplclust(const PointCloud &cloud,
                         const TriplClustParameters &parameters);

#endif