# SAT.ppDataHolder()

## Overview:
_A data structure to permit population with ppData_

- ppDataHolder  A {2 x N_TRIALS} Cell array containing point-process  observations collected during recording trials. 
- Each trial is represented as a column of the cell array. SDO Analysis assumes a level of stationarity to the signal; that different trials differ in time, but not in principle signal behavior. 

```mermaid

flowchart TD

%% Define styles - CONSERVED!
classDef dataObj fill: #EACE79,stroke:#333,stroke-width:2px; 
classDef codeObj fill: #90B963,stroke:#333,stroke-width:2px;
classDef classObj fill: #B1E2E9,stroke:#333,stroke-width:2px;
classDef paramObj fill: #D6766F,stroke:#333,stroke-width:2px

A[N_TRIALS]
B[N_PP_CHANNELS]
C["SAT.ppDataHolder_new.m()"]
D[ppdh]

A--param-->C
B--param-->C
C--makes-->D

%% Assign classes to Nodes
class D dataObj;
class C codeObj;
class 00 classObj;
class A,B, paramObj;

```


## Usages: 

> ppdh = SAT.ppDataHolder_new(N_TRIALS, N_PP_CHANNELS)

### Inputs
- ```N_TRIALS``` 
    - [Int]. Number of Trials in the dataset/ trials to use. 
- ```N_PP_CHANNELS```
    - [Int]. Number of Channels in the dataset/ channels to use. 

### Output:  
 - ```ppdh```
     - {2, N_TRIALS} cell array. 
     - __ppdh{1,N}__ contains a (1,N_PP_CHANNELS) structure to populate with primary data. Structure contains the following fields: 
        - ```.sensor```  : A string or character unique identifier corresponding to this channel's point-process data 
        - ```.times```  : A [1,K] (Row) Vector containing the event  times for the given point-process. These time points should be in the same units and relative start time as the data in the xtData channel against which it will be compared with the SDO.
        - ```.waves```  : A [K,M] Array of [1,M] waveforms associated with spiking events.
        - ```.nEvents```  : A (1,1) integer count of the number of elements  in  ```.times```.  If not populated here, will be populated during import.
        - ```.fs``` : (1,1) Numeric. Sample frequency for the spiking channels. 
        - ```.shuffle```: [L,N] array of L shuffled spike times of the observed spike train of N spikes. Can be left empty. 
     - __ppdh{2,N}__ contains a structure with metadata to populate. This data will be passively appended to the  sdo  structure later, to  keep track of associated pre-processing parameters associated with SDO generation. It is a structure composed of the following fields: 
          - ```.trialNumber```: [Integer]: A simple index of trial number  by position. This value is not directly utilized by the  computeSDO  code, and may be overridden. 

!!! warning
     The number of channels in the dataset must not change in number or order across channels. Channels can contain no data (in the case of ppDataCell), but the channels should still be present. 


## Utility: 
    - Generates an empty  ppData  structure, a data holder  for point process data. 
    - User data must be bungled to fit this format. 
## Prerequisites :
    - None 

## Example Code 
```
>> numberTrials = 20; 
>> numberNeurons = 10; 

ppdh = SAT.ppDataHolder_new(numberTrials, numberNeurons); 

for tr = 1:numberTrials
    for nn = 1:numberNeurons
        %// populate ppData;
        neuronName = strcat(‘neuron’, num2str(n));
        ppdh{1,tr}(n).sensor    = neuronName;
        ppdh{1,tr}(n).time      = ourSpikeData{n};
        ppdh{1,tr}(n).counts    = length(ppData{1,tr}(n).time);
    end
end

```


## IMPORTANT NOTES  :  
- ppDataHolder  is a homogeneous structure. During data population, the row index for each trial should be consistent across the entire data cell. (e.g. ‘Neuron 3’ on row 3 in trial 1 should also be on row 3 of trial 10).

-  Events which do not occur during a trial should still be given a field (and ‘time’ field left empty) to thus maintain this homogenous data structure. 

- Additional fields may be incorporated into the first row of  ppData  (primary data) array, however, these will not  be used for SDO analysis, nor passed to the  sdo  structure. 

- Additional fields may be incorporated into the second row of  ppData  (metadata) array. These fields  will be passively passed to the  sdo  structure. This permits  an investigator to pass trial-wise notes, annotation, and data pre-processing parameters into the  sdo  structure for later comparison or review. 

