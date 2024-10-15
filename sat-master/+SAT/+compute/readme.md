**Core Compute Folder** 

This is the folder containing the algorithms to estimate the SDO directly from observed probability distributions (sdo#.m). Additional algorithms may be added as useful or necessary. 
- sdo3.m | original SDO estimation using matrix outer product
- sdo5.m | asymmetric SDO estimation
- sdo7.m | constrained-optimization method minimizing dpx prediction error. 

Also contained are the wrapper scripts which perform the computations for the spike-triggered, spike-shuffled, and background SDOs (populateSDOArray#.m)
- populateSDOArray3.m | Current implementation, designed for use with the <em>sdoMultiMat</em> and <em>sdoMat</em> classes, with calls for parallel-computing GPU acceleration. 
