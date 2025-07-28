# pxTools.getH0Array()

## Overview:
_Core method for extracting a Diagonal or Gaussian Kernel Matrix_

!!! note
     This method should be compatible with older versions of MATLAB <2019b, as it uses inputParser instead of argument parser.


```mermaid

flowchart TD

%% Define styles - CONSERVED!
classDef dataObj fill: #EACE79,stroke:#333,stroke-width:2px; 
classDef codeObj fill: #90B963,stroke:#333,stroke-width:2px;
classDef classObj fill: #B1E2E9,stroke:#333,stroke-width:2px;
classDef paramObj fill: #D6766F,stroke:#333,stroke-width:2px

p0[N_BINS]
p1[PX_FSM_WID]
p2[PX_FSM_STD]
p3["type"]
p4["normalize"]

A[pxtools.getH0Array.m]
B[h0Array]

p0 --param-->A
p1 --param-->A
p2 --param-->A
p3 --param-->A
p4 --param-->A
A --makes-->B

%% Assign classes to Nodes
class B dataObj;
class A codeObj;
class 00 classObj;
class p0,p1,p2,p3,p4 paramObj;

```

## Usages: 

```
[h0Array] = pxTools.getH0Array(N_BINS, PX_FSM_WID=0, PX_FSM_STD=0, 'type'='M', 'normalize'=0)
```

### Inputs
- ```N_BINS``` 
    - [Integer].
    - Number of State bins for the [```N_BINS```, ```N_BINS```] matrix. 
- ```PX_FSM_WID```
     - [Numeric] Z > 0
     - Number of states to calculate Gaussian over. (Precision)
     - if ```0```, effectively returns a diagonal matrix. 
     - Default = 0
- ```PX_FSM_STD```
     - [Numeric] N >= 0
     - The $\sigma$ of the Gaussian, in states. 
     - Default = ```0```
     - If ```0```, return a diagonal matrix. 
- ```type```
     - {'M', 'L'}
     - The type of Matrix to return: 
          - ```M```: Markov Transition Matrix 
          - ```L```: SDO (Difference) Matrix
     - Default = ```M```
- ```normalize```
     - [0/1]
     - Whether to ensure that each column sums to 1 / 0. 
     - Default = ```1```

### Output:  
- ```h0Array```
     - H0 (Gaussian) 
          - if ```L```: Return the linear difference operator. 
          - if ```M```: Return the Markov transition operator.

