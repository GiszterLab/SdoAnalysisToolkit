# SAT.compute.sdo3.m 

## Algorithm

## Overview:
- 3rd-Generation Estimation Algorithm for SDOs
- Uses the __Linear Estimation__ method efficiently.

```mermaid

flowchart TD

%% Define styles - CONSERVED!
classDef dataObj fill: #EACE79,stroke:#333,stroke-width:2px; 
classDef codeObj fill: #90B963,stroke:#333,stroke-width:2px;
classDef classObj fill: #B1E2E9,stroke:#333,stroke-width:2px;
classDef paramObj fill: #D6766F,stroke:#333,stroke-width:2px

A(px0)
B(px1)
C(obsWise)
D(rescale)
E(parallelCompute)
F[sdo3.m]
G(L)
H(M)
I(L_norm)

A--takes-->F
B--takes-->F
C--param-->F
D--param-->F
E--param-->F
F--makes-->G
F--makes-->H
F--makes-->I


%% Assign classes to Nodes
class A,B,G,H,I dataObj;
class F codeObj;
class _ classObj;
class C,D,E paramObj;

```


## Usages: 
```
 [L, M, L_norm] = sdo3(px0, px1, ...
 obswise=0, "rescale"=1, "parallelCompute"=0)
```
### Inputs
- ```px0``` 
    - [N_STATES,N_OBSERVATIONS] numeric data array; 
    - column vectors of probability distributions relating the pre-spike/pre-index interval. 
- ```px1``` 
    - [N_STATES,N_OBSERVATIONS] numeric data array; 
    - column vectors of probability distributions.  
- ```obsWise```
    - [Boolean]
    - Default = 0.
    - If true, calculate an SDO for each observation (returning a 3D array of SDOs). 
- ```"rescale"```
    - [Boolean]
    - Default = 1. 
    - If false, do not normalize SDOs across numbers of spikes. (The returned ```L``` and ```M``` values represent sums of dynamics instead of averages). 
- ```"parallelCompute"```
    - [Boolean]
    - Default = 0. 
    - If true, attempt to perform SDO calculations on the GPU. Requires MATLAB's parallel computing toolbox. 

### Output:  
- ```L```: The difference SDO. 
    - This is the version estimated by channel variance. 
    - This is a [N_STATES, N_STATES] matrix, unless SDOs are calculated observation-wise. 
- ```M```: This is the joint distribution of state. 
    - This version is normalized by channel variance. Normalizing each column to 1 will provide a left Markov transition matrix. 
- ```L_norm```: The difference SDO. 
    - This version is the conditional differences of state (which can be used for forward predictions from initial distributions).

