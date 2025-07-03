# pxTools.matrixRandomWalk()

## Overview:
_Core method for simulating stochastic realizations of signal from a static transition matrix_


!!! note
     This method should be compatible with older versions of MATLAB <2019b, as it uses inputParser instead of argument parser.


```mermaid

flowchart TD

%% Define styles - CONSERVED!
classDef dataObj fill: #EACE79,stroke:#333,stroke-width:2px; 
classDef codeObj fill: #90B963,stroke:#333,stroke-width:2px;
classDef classObj fill: #B1E2E9,stroke:#333,stroke-width:2px;
classDef paramObj fill: #D6766F,stroke:#333,stroke-width:2px

p0(N_STEPS)
p1(N_SIM)
p2(startVal)

C(mat)
A[pxtools.getH0Array.m]
B[randWalkMat]

C --takes-->A
p0 --param-->A
p1 --param-->A
p2 --param-->A
A --makes-->B

%% Assign classes to Nodes
class B,C dataObj;
class A codeObj;
class 00 classObj;
class p0,p1,p2,p3,p4 paramObj;

```

## Usages: 

```
[randWalkMat] = pxTools.matrixRandomWalk(mat, N_STEPS, N_SIM, 'startVal'='None')
```

### Inputs
- ```mat```
     - Markov transition matrix. 
- ```N_STEPS```: 
     - [Int] (Z>0)
     - Number of steps to simulate over. 
- ```N_SIM```: 
     - Number of simulations to make. 
     - [Int] (Z>0)
- ```startVal```
     - {'None', [Int], Vector}
          - ```'None'```: Initialize from a flat distribution. 
              - Default
          - ```[Int]```: Initialize from a single state. 
          - ```[Vector]```: Initialize from an input distribution.  

### Output:  
- ```randWalkMat```
     - [N_SIM, N_STEPS] matrix
     - Contains the discrete simulations. 

