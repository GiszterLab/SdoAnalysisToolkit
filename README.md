# SDO Analysis Toolkit (SAT)
[V 1.0]
MATLAB Package for implementing Stochastic Dynamic Operator (SDO) methods from time series and point process data. 


____*INSTALLATION*____: 

Add 'sat-master' to path ('add Folder with Subfolders')

Demonstration of the STA and SDO methods, and their comparisons can be evaluated with 'ssta_sdo.m'

Description of the included scripts may be found in the 'documentation' folder. 

SAT capabilities demonstrated using either 'sdoAnalysis_demo.m' or 'sdoAnalysis_demo_OOP.m' 

OOP-Based Class/Methods:

_______*CLASSES*_______: 

ppDataCell 	- Class for point-process (i.e. spike) data

xtDataCell	- Class for time-series (e.g. EMG) data 

pxt 		    - Class for (observed) probability distribution data (at sampled time points)

sdoMat  	  - Class for holding the SDO, along with other hypotheses

sdoMultiMat - Class for computing multiple SDOs from ppDataCell and xtDataCell
