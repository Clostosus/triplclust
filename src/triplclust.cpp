//
// triplclust.cpp
//     Library implementation of the TriplClust algorithm.
//

#include "triplclust.hpp"

#include <vector>

#include "graph.h"
#include "output.h"
#include "triplet.h"

cluster_group triplclust(const PointCloud &cloud,
                         const TriplClustParameters &parameters) {
  // Step 1) smoothing by position averaging of neighboring points
  PointCloud cloud_smooth;
  smoothen_cloud(cloud, cloud_smooth, parameters.r);

  if (parameters.verbose > 1) {
    bool rc = cloud_to_csv(cloud_smooth);
    if (!rc)
      std::cerr << "[Error] can't write debug_smoothed.csv" << std::endl;
    rc = debug_gnuplot(cloud, cloud_smooth);
    if (!rc)
      std::cerr << "[Error] can't write debug_smoothed.gnuplot" << std::endl;
  }

  // Step 2) finding triplets of approximately collinear points
  std::vector<triplet> triplets;
  generate_triplets(cloud_smooth, triplets, parameters.k, parameters.n,
                    parameters.a);

  // Step 3) single link hierarchical clustering of the triplets
  cluster_group cl_group;
  compute_hc(cloud_smooth, cl_group, triplets, parameters.s, parameters.t,
             parameters.tauto, parameters.dmax, parameters.is_dmax,
             parameters.linkage, parameters.verbose);

  // Step 4) pruning by removal of small clusters
  cleanup_cluster_group(cl_group, parameters.m, parameters.verbose);
  cluster_triplets_to_points(triplets, cl_group);

  // Optionally split up clusters at gaps > dmax
  if (parameters.is_dmax) {
    cluster_group cleaned_up_cluster_group;
    for (cluster_group::iterator cl = cl_group.begin(); cl != cl_group.end();
         ++cl) {
      max_step(cleaned_up_cluster_group, *cl, cloud, parameters.dmax,
               parameters.m + 2);
    }
    cl_group = cleaned_up_cluster_group;
  }

  return cl_group;
}