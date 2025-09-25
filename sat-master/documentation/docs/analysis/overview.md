# Custom Analysis

## Visual Overview:

__Overview of the Class-Method Interactions__


``` mermaid

flowchart TD

%% {init: {'flowchart' : {'curve' : 'linear'}}}%%

%% Define styles - CONSERVED!
classDef dataObj fill: #EACE79,stroke:#333,stroke-width:2px; 
classDef codeObj fill: #90B963,stroke:#333,stroke-width:2px;
classDef classObj fill: #B1E2E9,stroke:#333,stroke-width:2px;
classDef paramObj fill: #D6766F,stroke:#333,stroke-width:2px

%% Insert diagram here. 
   
A("emgData.m") --Reads--> B{{"xtDataCell"}}
C("spikeData.m")--Reads--> D{{"ppDatacell"}}
D--Imports-->E{{"sdoMultiMat"}}
B--Imports-->E
B--Imports-->F{{"pxtDataCell [PreSpike]"}}
B--Imports-->G{{"pxtDataCell [PostSpike]"}}
D--Imports-->F
D--Imports-->G
E--Exports-->H{{"sdoMat"}}
F--Imports-->H
G--Imports-->H
H--Computes-->J{{"pxtDataCell [Predicted]"}}
G--Compares-->I{{"predictionErrror"}}
J--Compares-->I

%% Assign classes to Nodes
class A,C dataObj;
class _ codeObj;
class B,D,E,F,G,H,I,J classObj;
class 01,02,03 paramObj;
```


_Overview of Interactions of the OOP-based custom data classes._

- Time  series data is imported into [xtDataCell](../classes/m_xtDataCell.md) and point-process data into [ppDataCell](../classes/m_ppDataCell.md). 
- (Alternatively, these may be loaded into the newer [xtDataCell2](../classes/m_xtDataCell2.md) and [ppDataCell2](../classes/m_ppDataCell2.md) classes). 
- Probability distributions of state are optionally generated for the  pre-spike and  post-spike distribution using the [pxtDataCell](../classes/m_pxtDataCell.md)  class. 
- The  difference between [pxtDataCell](../classes/m_pxtDataCell.md) class data is used to generate the  [sdoMat](../classes/m_sdoMat.md) class.
- The [sdoMat](../classes/m_sdoMat.md) class  may then produce a predicted probability distribution [pxtDataCell](../classes/m_pxtDataCell.md) class. 
- The difference between the  predicted and observed [pxtDataCell](../classes/m_pxtDataCell.md) classes produces an instance of the the [predictionError](../classes/m_predictionError.md) class. 
- The [predictionError](../classes/m_predictionError.md) class can be used to directly plot prediction errors by matrix hypothesis.
- A [sdoMultiMat](../classes/m_sdoMultiMat.md) class may be used to compute SDOs within a  selected range of units within [xtDataCell](../classes/m_xtDataCell.md) and [ppDataCell](../classes/m_ppDataCell.md), using a common set of parameters, from which individual [sdoMat](../classes/m_sdoMat.md) objects may be extracted for further analysis.



### [Example SDO Analysis](./example_analysis.md)


## Description
The  SDO  Analysis Toolkit (SAT) contains both programmatic functions  /  scripts and class-method based implementations of the SDO. Custom data classes are initialized with default parameters, wrap the included functions into objects, from which functions may be called as methods of the  object directly. This later ‘object-oriented programming’ (OOP)  method allows for standardization of data structures and  makes function calls more accessible and  efficient (and provides ‘guiderails’ to  minimize the chance of running into errors). 

!!! info
      OOP-based methods are the preferred implementation of the  _SDO  Analysis Toolkit_. Because these methods use argument-parsing, they require MATLAB v. 2019a or newer. 


To interpret the outcome of SDO analysis, it is pertinent to understand what parameters are being called by the nested functions. Optimial analysis will likely require adjusting analysis parameters to fit the experimental question.

The public-facing classes provide a reliable method of adjusting ahd passing these parameters. Advanced  users  who  would like to  reliably adapt existing methods for their particular data sets may find direct calls to the function library  to  be  better suited. 

Some standalone  methods (such as drawing  the  waveforms of the simple STA) are not incorporated into the OOP classes. Thus, we present both methods here for convenience. 


There is significant interconvertibility between structures  generated  by the stand-alone functions and the class methods. xtData and ppData  data holder structures may be directly imported into the  ```xtDataCell```  and ```ppDataCell``` classes as the ‘data’ field.  Particular SDOs selected from the sdo data structure generated from the 
function-based methods may also be directly imported into the sdoMat  class.