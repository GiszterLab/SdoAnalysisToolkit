# Function Library

## Overview:
_A series of call-out functions and their parameters_

### Constructors: 

[SAT.ppDataHolder_new()](m_SAT_ppDataHolder_new.md)

_Constructor for ppData_

[SAT.xtDataHolder_new()](m_SAT_xtDataHolder_new.md)

_Constructor for xtData_

[SAT.validateDataHolders()](m_SAT_validateDataCells.md)

### SDO Estimation (SAT.compute.)

[sdo3.m](m_SAT_compute_sdo3.md)
_Linear Estimation_

[sdo5.m](m_SAT_compute_sdo5.md)
_Asymmetric Residuals_

[sdo7.m](m_SAT_compute_sdo7.md)
_Optimized_

### sdoUtils (SAT.sdoUtils)

[islinearsdo](./m_SAT_sdoUtils_islinearsdo.md)

_Method to check that a matrix is an conforming SDO_


### pxTools Library

!!! note
     This only represents a portion of the total library. We can add more files here as they are necessary. 


[pxtools.getXtStateMap](./m_pxTools_getXtStateMap.md)

_Core method for converting state to distributions_

[pxtools.getXfromPx](./m_pxTools_getXfromPx.md)

[pxTools.getH0Array](./m_pxTools_getH0Array.md)

_Return a Gaussian Kernel Array_

[pxTools.matrixRandomWalk](./m_pxTools_matrixRandomWalk.md)

_Generate stochastic realizations of a signal from a Markov matrix_