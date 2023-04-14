# SDO Analysis Toolkit (SAT) [V 1.0]
MATLAB Package for implementing Stochastic Dynamic Operator (SDO) methods from time series and point process data. When applied to neurophysiological data recordings, 
SDO methods improves upon the classical spike-triggered average. 

![SDO_Logo](https://github.com/GiszterLab/SdoAnalysisToolkit/blob/main/SAT_Logo.png)



__Prerequisites__: 

- Class-Based Implementation requires MATLAB 2019a or newer.
- Programmatic Implementation requires MATLAB 2015 or newer. 

__Toolboxes__: 
- <em> Statistics and Machine Learning Toolbox </em>
- <em> Signal Processing Toolbox </em>
- <em>Image Processing Toolbox </em> (Optional visualization)
- <em> DSP System Toolbox </em> (Optional Notch Filtering Method on <em>xtDataCell</em>)


## Citation Requirement
If you use any version of this software, please cite : ... 

## Installation

A full walkthrough for installing and using the <em> SDO Analysis Toolkit </em> can be found within '\sat-master\documentation'.

1. Download the <em> SDO Analysis Toolkit </em> onto local device. 
2. Add 'sat-master' to path ('add Folder with Subfolders') within MATLAB. 
3. Place demonstration data ('xtData.mat', 'ppData.mat') within '\sat-master\demoData\'. 
4. Run 'ssta_sdo.m' to produce plots which compare the STA vs. SDO methods within the trial dataset. 
5. Run 'sdoAnalysis_demo.m' or 'sdoAnalysis_demo_OOP.m' for performing the complete trial analysis. 
  1. When prompted, select 'xtData.mat' from within the '\sat-master\demoData\' folder. 
  2. When prompted, select 'ppData.mat' from within the '\sat-master\demoData\' folder. 

## Importing Custom Data

User data must be first formatted for use within the <em>Toolkit</em>. 

Example Data Structures are trialwise data contained within a {2, N_TRIALS} <em>cell</em>. 
- The first row of each data structure contains primary user data, which has been bungled as described below. 
- The second row corresponds to trialwise metadata which should be retained in the final element (Note that in this latter case, the parameters are passed passively). 
- Primary data corresponds to a row within each trial. 

Data structures assume a homogeneous ordering to the data, with requirements: 
- The number of elements does not change from trial-to-trial (missing observations are left as empty cells)
- The duration of observations <em> within a trial </em> does not change. (i.e., co-measured data channels are the same size). 
- The sample frequency is consistent across elements <em> within a data structure </em>. 

An empty data holder for time series (x,t) data can be generated by: 
> $ SAT.xtDataHolder_new(N_TRIALS, N_CHANNELS)

An empty data holder for point-process (pp) data can be generated by: 
> $ SAT.ppDataHolder_new(N_TRIALS, N_CHANNELS)

Data holders generate the folowing 

Successful validation of user data formating and importing can be tested by: 
> $ SAT.validateDataCells


## Objected-Oriented Data Processing:

### Classes

**ppDataCell** 	- Class for point-process (i.e. spike) data

**xtDataCell**	- Class for time-series (e.g. EMG) data 

**pxt** 		    - Class for (observed) probability distribution data (at sampled time points)

**sdoMat**  	  - Class for holding the SDO, along with other hypotheses

**sdoMultiMat** - Class for computing multiple SDOs from ppDataCell and xtDataCell

## License
