# SDO Analysis Toolkit (SAT) [V 1.0]
MATLAB Package for implementing Stochastic Dynamic Operator (SDO) methods from time series and point process data. SDO methods improves upon the classical spike-triggered average for neural analysis. 

If you use this software, please cite : ... 

__Prerequisites__: 

- Class-Based Implementation requires MATLAB 2019a or newer.
- Programmatic Implementation requires MATLAB 2015 or newer. 

## Installation

A full walkthrough for installing and using the <em> SDO Analysis Toolkit </em> can be found within '\sat-master\documentation'.

1. Download the <em> SDO Analysis Toolkit </em> onto local device. 
2. Add 'sat-master' to path ('add Folder with Subfolders') within MATLAB. 
3. Place demonstration data ('xtData.mat', 'ppData.mat') within '\sat-master\demoData\'. 
4. Run 'ssta_sdo.m' to produce plots which compare the STA vs. SDO methods within the trial dataset. 
5. Run 'sdoAnalysis_demo.m' or 'sdoAnalysis_demo_OOP.m' for performing the complete trial analysis. 
  1. When prompted, select 'xtData.mat' from within the '\sat-master\demoData\' folder. 
  2. When prompted, select 'ppData.mat' from within the '\sat-master\demoData\' folder. 

## OOP-Based Class/Methods:

### Classes

ppDataCell 	- Class for point-process (i.e. spike) data

xtDataCell	- Class for time-series (e.g. EMG) data 

pxt 		    - Class for (observed) probability distribution data (at sampled time points)

sdoMat  	  - Class for holding the SDO, along with other hypotheses

sdoMultiMat - Class for computing multiple SDOs from ppDataCell and xtDataCell
