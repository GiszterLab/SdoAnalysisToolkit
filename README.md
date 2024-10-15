# SDO Analysis Toolkit (SAT) [V 1.1]
MATLAB Package for implementing Stochastic Dynamic Operator (SDO) methods for stochastic control and prediction, using time series and point process data. 
When applied to neurophysiological data recordings, SDO methods improves upon the classical spike-triggered average when generating predictions of state near spike. 

![SDO_Logo](https://github.com/GiszterLab/SdoAnalysisToolkit/blob/main/SAT_Logo.png)


__Prerequisites__: 

- Class-Based Implementation requires MATLAB 2019a or newer (Recommended). 

__Toolboxes__: 
- <em> Statistics and Machine Learning Toolbox </em>
- <em> Signal Processing Toolbox </em>
- <em> Image Processing Toolbox </em> (Optional visualization)
- <em> DSP System Toolbox </em> (Optional Notch Filtering Method on <em>xtDataCell</em>)


## Citation Requirement
If you use any version of this software, please cite [our paper](https://pubmed.ncbi.nlm.nih.gov/39375031/). Additional details can be found in the supplemental of [our preprint](https://www.biorxiv.org/content/10.1101/2024.05.10.593606v1)

If you modify or adapt the <em>Toolkit</em>, please contact the authors or share your modifications under the 'Discussions' tab. We strive to make SDO Analysis accessible and interpretable for physiologists. Please let us know if you run into difficulties.  

## Installation

A full walkthrough for installing and using the <em> SDO Analysis Toolkit </em> can be found within '\sat-master\documentation'. More information can also be found on the [wiki](https://github.com/GiszterLab/SdoAnalysisToolkit/wiki). 

A quick-run MATLAB live script is included in the folder, as 'sdoAnalysis_demo.mlx'. This can be used as an introduction to basic use of the toolkit. 

1. Download the <em> SDO Analysis Toolkit </em> onto local device. 

2. Add 'sat-master' to path ('add Folder with Subfolders') within MATLAB.

3. For generating the figures from the paper, Download/Clone the Full Demo Data (~400 MB) from https://github.com/GiszterLab/SdoAnalysisToolkit_DemoData

4. Run 'ssta_vs_sdo.m' as a standalone function to produce plots which compare the STA vs. SDO methods within the trial dataset. 

5. Run 'sdoAnalysis_demo.mlx' (function-calls) or 'sdoAnalysis_demo_OOP.m' (class-methods) for performing the complete SDO trial analysis. 
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

An empty data holder for time series (x,t) data can be generated within MATLAB by the command: 
~~~
> $ xtData = SAT.xtDataHolder_new(N_TRIALS, N_CHANNELS)
~~~
An empty data holder for point-process (pp) data can be generated within MATLAB by the command: 
~~~
> $ ppData = SAT.ppDataHolder_new(N_TRIALS, N_CHANNELS)
~~~
Successful validation of user data formating and importing can be tested by the command: 
~~~
> $ SAT.validateDataHolders(xtData, ppData);  
~~~
xtData bungled into the xtData holder format may be imported into the 'xtDataCell' class for easier manipulation. Use: 
~~~
> $ xtDataCell.import(xtData); 
~~~
ppData bungled into the ppData holder format may be imported into the 'ppDataCell' class for easier manipulation. Use: 
~~~
> $ ppDataCell.import(ppData);
~~~

## Performing Basic Analysis

An <em>sdoMultiMat</em> class can then be used to batch-compute all combinations of spike vs. signal data using default settings. 
Initialize the <em>sdoMultiMat</em>
~~~
> $ smm = sdoMultiMat();
> $ smm.compute(xtdc,ppdc); % // This generates ALL SDO combinations;
> $ smm.findSigSdos(); %// Determine SDOs which significantly differ from baseline.  
~~~
 Note that changing various properties (e.g., filtering, assigning different durations, number of spikes, etc) will affect the final SDO. 


 Determine the model of best-fit between different hypothesized fits between the <em>prespike</em> and <em>postspike</em> distribution. 
 ~~~
> $ pe = smm.getPredictionError(xtdc, ppdc, XT_CH_NO, PP_CH_NO); %// These numbers correspond to channel indices for the signals and spikes
> $ pe.plot();
~~~


## Objected-Oriented Data Processing:

Using the below classes, different data modalities may be handled more abstractly and efficiently. See 'sdoAnalysis_demo_OOP.m' for usage of the class methods for performing SDO Analysis. 

### Classes

**ppDataCell** 	- Class for point-process (i.e. spike) data

**xtDataCell**	- Class for time-series (e.g. EMG) data 

**pxtDataCell** - Class for (observed) probability distribution data (at sampled time points)

**sdoMat**  	  - Class for holding the SDO, along with other hypotheses

**sdoMultiMat** - Class for computing multiple SDOs from ppDataCell and xtDataCell

**predictionError** - A support class for computing and plotting the prediction errors between the observed and hypothesis-predicted values. 

## Externally-Sourced Code
Violin plots used to visualize the distribution of prediction likelihoods were produced with code written by Holger Hoffmann available on the [MATLAB File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/45134-violin-plot) 

## License
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
