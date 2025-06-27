# Custom Analysis

## Overview:

__Overview of the Class-Method Interactions__


``` mermaid

flowchart TD

%% Define styles - CONSERVED!
classDef dataObj fill: #EACE79,stroke:#333,stroke-width:2px; 
classDef codeObj fill: #90B963,stroke:#333,stroke-width:2px;
classDef classObj fill: #B1E2E9,stroke:#333,stroke-width:2px;
classDef paramObj fill: #D6766F,stroke:#333,stroke-width:2px

%% Insert diagram here. 
   
A("emgData.m") --Reads--> B("xtDataCell")
C("spikeData.m")--Reads--> D("ppDatacell")
D--Imports-->E("sdoMultiMat")
B--Imports-->E
B--Imports-->F("pxtDataCell [PreSpike]")
B--Imports-->G("pxtDataCell [PostSpike]")
D--Imports-->F
D--Imports-->G
E--Exports-->H("sdoMat")
F--Imports-->H
G--Imports-->H
H--Computes-->I("pxtDataCell [Predicted]")
G--Measures-->I

%% Assign classes to Nodes
class A,C dataObj;
class _ codeObj;
class B,D,E,F,G,H,I classObj;
class 01,02,03 paramObj;

```


_Overview of Interactions of the OOP-based custom data classes. Time  series data is imported into xtDataCell and point-process data into ppDataCell. Probability distributions of state are generated for the  pre-spike and  post-spike distribution using the pxtDataCell  class. The  difference between pxtDataCell class data is used to generate the  sdoMat class. The sdoMat  may then produce a predicted probability distribution pxtDataCell class. The difference between the  predicted and observed pxtDataCell classes is the prediction  error. A sdoMultiMat class may be used to compute SDOs within a  selected range of units within xtDataCell and ppDataCell, using a common set of parameters, from which individual sdoMat objects may be extracted for further analysis._

## Description
The  SDO  Analysis Toolkit (SAT) contains both programmatic functions  /  scripts and class-method based implementations of the SDO. Custom data classes are initialized with default parameters, wrap the included functions into objects, from which functions may be called as methods of the  object directly. This later ‘object-oriented programming’ (OOP)  method allows for standardization of data structures and  makes function calls more accessible and  efficient (and provides ‘guiderails’ to  minimize the chance of running into errors). 

!!! info
      OOP-based methods are the preferred implementation of the  _SDO  Analysis Toolkit_. Because these methods use argument-parsing, they require MATLAB v. 2019a or newer. 


Nonetheless, it  is important to understand the parameters which are being  called  by  the  nested functions,  to best optimize the  parameters  for  their dataset. Advanced  users  who  would like to  reliably adapt existing methods for their particular data sets may find direct calls to the function library  to  be  better suited. Some standalone  methods (such as drawing  the  waveforms of the simple STA) are not incorporated into the OOP classes. Thus, we present both methods here for convenience. 


There  is  significant  interconvertibility  between  structures  generated  by  the  stand-alone  functions  and  the  class 
methods.  xtData  and  ppData  data  holder  structures  may  be  directly  imported  into  the  ```xtDataCell```  and 
```ppDataCell```  classes  as  the  ‘data’  field.  Particular  SDOs  selected  from  the  sdo  data  structure  generated  from  the 
function-based methods may also be directly imported into the  sdoMat  class.