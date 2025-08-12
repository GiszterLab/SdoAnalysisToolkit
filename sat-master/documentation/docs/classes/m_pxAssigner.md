# dataCell.pxAssigner

## Utility: 
Class for sampling, holding, and manipulating probability data : p(x).  

## Compositions:
- ```sdoMat2```
- ```SAT.analyzer```

## Overview: 
```mermaid
classDiagram
    class pxProperties{
        +weighting
        +G_smoothFWidth_Pts
        +G_smoothFStdev_Pts
    }

    class pxAssigner {
        ___Defined:___
        +data 
        +Sensor
        -filteredDistributions
        ___Dependent:___
        +nStates
        +nTrials
        +nChannels
        +nReplicates
        +nObservations
        -sampledData

        +assignPx()
        +assignPxRaw()
        +gaussianFilter()
        +subsample()
        +imagesc()
        +plot()
        +hcat()
        +vcat()
        -isCompatible()
  }

    pxAssigner *-- pxProperties

```
## Properties: 
* ### ```assignPx```(stateMap, intervalData)

* ### ```assignPxRaw```(stateMap, xCell)
    - ```xCell``` is a cell of data.

* ### ```gaussianFilter```():

* ### ```subsample```(useXtChannels, useTrials, usePpChannels)

* ### ```imagesc```(useTrials, useChannels, useReplicates)

## Methods