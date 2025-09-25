# _sdoMultiMat.m_

## Utility: 
Custom  Handle  class to generate single SDOs from instances of [xtDataCell](./m_xtDataCell.md) and [ppDataCell](./m_ppDataCell.md). 

!!! note
    This class is functional, but deprecated. The [SAT.analyzer](m_analyzer.md) class eclipses this class in functionality. 

## Alias
Instances of this class in the documentation and annotations is assigned the alias **smm**. 


## Overview: 


```mermaid
classDiagram
    class sdoMultiMat {
        +data
        +metadata
        +nTrials
        +nChannels
        +sensor
        -discretizedData
        +import()
        +plot()
        +filter()
        +getValuesAtIndices()
    }
```

## Constructor
_Call within MATLAB_
~~~
smm = sdoMultiMat(); 
~~~

!!! bug TODO: 
       - Upgrade this section with metadata classes on xtDataCell; import metadata from pxtDataCell. 

## Properties: 
* ```.nXtChannels``` 
    -  [int] Number of xtChannels used from  xtDataCell 
    -  Populated by  ```.compute``` 

* ```.nPpChannels``` 
    -  [int] Number of ppChannels 

*  ```.xtName``` 
      - xtDataCell.dataField 
      - Populated by  ```.import``` 

* ```.ppName```  
   -  ppDataCell.dataField 
   -  Populated by  ```.import``` 

* ```.xtChName```
    - xtDataCell channel name of imported data. 
    - Populated by  ```.import``` 

* ```.ppChName``` 
    - ppDataCell channel name of imported data.  
    - Populated by  ```.import``` 

* ```.pxtNames``` 
    - {1x nPxtTypes} cell of of  char  . Corresponds to type  of prediction.     
    - Populated by  ```.import`` 
    - Populated by ```.comparePxt``` 

* ```.nPxtTypes``` 
    - [int]. Number of dataTypes/predictions contained within the  [pxtDataCell](./m_pxtDataCell.md).   

* ```.nEvents``` 
    - [int]. Number of events around which distributions are drawn. 

* ```.nShuffles``` 
    -  [int]. Number of shuffles generated in  pxt. 
    -  Populated by  ```.import```  from  [ppDataCell](./m_ppDataCell.md)

* ```.xtProperties``` 
    -  Metadata of  [xtDataCell](./m_xtDataCell.md) 

* ```.ppProperties``` 
    -  Metadata of  [ppDataCell](./m_ppDataCell.md) 

* ```.px0_duraMs``` 
    -  [double]. Duration of interval over which to derive event-wise distributions. 
    -  If .duraMs  < 0, then sample this interval PRIOR to  event. 
    -  If .duraMs  > 0, then sample this interval AFTER to  event. 

* ```.px1_duraMs``` 
    -  [double]. Duration of interval over which to derive event-wise distributions.
    -  If .duraMs  < 0, then sample this interval PRIOR to  event.-  If .duraMs  > 0, then sample this interval AFTER to  event. 

* ```.nShift``` 
    - Shift in the the start time for pre/post spike interval. See  SAT.computeSDO.m 
    -  Default = 1; 

* ```.zDelay``` 
    -  Interval between pre/post spike interval. See ```SAT.computeSDO.m``` 
    -  Default = 0; 

* ```.sdo```
    - [N_STATES,N_STATES] SDO (differential) matrix corresponding to the combination of xtDataCell channel and ppDataCell channel. 
    - Populated by ```.import``` 

* ```.filterWid``` 
    -  Width of the smoothing filter, in states. See  SAT.computeSDO.m 
    -  Default = 0; 

* ```.filterStd``` 
    -  Standard deviation of the smoothing filter, in states. See  ```SAT.computeSDO.m``` 
    -  Default = 0; 

* ```.nStates``` 
    -  Number of states used to rasterize signal. 
    -  Populated by .import  from [xtDataCell](./m_xtDataCell.md). 

*  ```.fs``` 
   -  Sample frequency of timeseries data. 
   -  Populated by  ```.import```  method. 
   -  Modified by  ```.resample```  method.   

* ```.stateMapping``` 
    -  [1 x N_STATES+1] corresponding to the edges of the state bins. 
    -  Populated by ```.import```  from  [xtDataCell](./m_xtDataCell.md). 

* ```.backgroundPx``` 
    -  [N_STATES x 1] Probability distribution; average P(x) 
    -  Populated by  ```.import``` 

* ```.backgroundMkv``` 
    -  [N_STATES x N_STATES] Markov Matrix, corresponding to background transitions (over ```.duraMs```). 
    -  Populated by  ```.import```

## (Selected) Methods  : 
* ```.compute``` ([xtDataCell](./m_xtDataCell.md), [ppDataCell](./m_ppDataCell.md), USE_XT_CH, USE_PP_CH); 
    ~~~   
    smm.compute(xtdc, ppdc, 6,4)

    % Calculate the SDO measured between the observed probability distributions in pxt0 and the transitions (post-spike) to pxt1.
    ~~~ 
    - if ```USE_XT_CH``` or ```USE_PP_CH``` are not provided, they will default to all the channels in the [xtDataCell](./m_xtDataCell.md) or [ppDataCell](./m_ppDataCell.md).

!!! note
    _sdoMultiMat_ does not contain an explicit import method, instead this is called directly from the script. 

* ```.findSigSdos(SIG_THRESH)```
    - Determines which SDOs significantly differ from shuffled-spike SDOs. 
    - If ```SIG_THRESH``` is not passed, tests will default to ```smm.sigPval.```

*  ```.plot(XT_CH_NO, PP_CH_NO)```
      - Plots all sdo Plot features. 
      - If ```XT_CH_NO``` and ```PP_CH_NO``` positional indices are passed, then it will only plot those/that set of SDOs.

* ```.getPredictionError(xtdc, ppdc, XT_CH_NO, PP_CH_NO)```
    - Returns and instance of the [predictionError](../classes/m_predictionError.md) class. 
    - Requires the original xtDataCell and ppDataCell class instances to construct, as with the channel indices of interest. 

* ```.getSdos(XT_CH_RANGE, PP_CH_RANGE)```
    - Returns a {1, length(XT_CH_RANGE)} cell array of raw SDOs. 
        - if only 1 xtChannel is used, will return a double matrix instead.
    - Each cell {1,n} contains a 3D doubles matrix with a third dimension of length(PP_CH_RANGE)

* ```.getNormSdos(XT_CH_RANGE, PP_CH_RANGE)```
    - Returns a {1, length(XT_CH_RANGE)} cell array of normalized SDOs. 
        - if only 1 xtChannel is used, will return a double matrix instead.
    - Each cell {1,n} contains a 3D doubles matrix with a third dimension of length(PP_CH_RANGE)





