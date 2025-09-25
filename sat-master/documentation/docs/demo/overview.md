# Demonstration of the SDO Analysis Toolkit. 

_Here we walk through the basics of using the OOP-classes, and what each step is for._

## Option 1: OOP-Based [Code Version 1.0] 

### 1. Initialize an empty data holders
The easiest way to use the SDO Analysis toolkit is to call, then populate the miminal data structures, when import these into the public classes. 

For time-series data (e.g., EMG, force traces, calcium transients, etc), we use the constructor _xtDataHolder_. 

Intialize an instance of this structure. 

~~~

>> numberTrials = 20;
>> numberChannels = 5;
xtData = SAT.xtDataHolder_new(numberTrials, numberChannels);

xtData = SAT.xtDataHolder_new(N_TRIALS, N_XT_CHANNELS); 
~~~
- Here, ```N_TRIALS``` refers to the number of independent divisions in your data. If your data is broken into multiple recording sessions, each should be assigned to an individual trial (trials do not need to be the same length). If your data is taken as a single, long, recording, you can leave N_TRIALS = 1. 
    - **NOTE**: The number of trials and time indexing (but not sample frequency) must be the same between _xtdh_ and _ppdh_
- Here, ```N_XT_CHANNELS``` is the number of independent recording channels in your time-series dataset. Note that the length of these channels must be identical within trials (i.e., for all time points, all channels must have some data). 


For point-process data (e.g., neural spikes, discrete events, calcium peaks), we use the construcor _ppDataHolder_. 

~~~
>> numberTrials = 20;
>> numberNeurons = 10;
ppData = SAT.ppDataHolder_new(numberTrials, numberNeurons);

ppData = SAT.ppDataHolder_new(N_TRIALS, N_PP_CHANNELS)
~~~
- Here, ```N_TRIALS``` refers to the number of independent divisions in your data. If your data is broken into multiple recording sessions, each should be assigned to an individual trial (trials do not need to be the same length). If your data is taken as a single, long, recording, you can leave N_TRIALS = 1. 
    
    - **NOTE**: The number of trials and time indexing (but not sample frequency) must be the same between _xtdh_ and _ppdh_

- Here, ```N_PP_CHANNELS``` is the number of independent recording channels in your point-process dataset (e.g., number of neurons/clusters). It is assumed that all channels have the potential for events over all time events (i.e., that regions with no spikes are due to no spiking events, not due to an inabiliy to record). 

### 2. Populate xtDataHolder (xtData) Structure

You will need to write a (minimal) amount of code to populate the _xtDataHolder_ structure with _your_ specific data structure. 

---
**xtData:** A {2 x N_TRIALS} Cell array containing analog time-series signals collected during recording trials.Each trial is represented as a column of the cell array. SDO Analysis assumes a level of stationarity to the signal; that different trials differ in time, but not in principle signal behavior.

**xtData{1,:}** Each cell in the first row contains primary data within 1 x N_PP_CHANNELS struct. This struct contains the following fields:
    
 - ```.electrode```: A string or character unique identifier corresponding to this time series data channel.

 - ```.envelope```: A [1 x N] (Row) vector containing the time-varying amplitude signal (or representation of the signal). This is the primary data used for STA and SDO analysis.
- ```.fs``` : The signal sampling frequency, used to align observations to time points.
- ```.times```: A [1 x N] (Row) Vector containing the matching time values, defined for each element of .envelope. These time points should be in the same units and relative start time as the data in the ppData against which it will be compared.

**xtData{2,:}**: Each cell in the second row contains metadata associated with each trial. This data will be
appended to the sdo structure later, to keep track of associated pre-processing parameters associated
with SDO generation. It is a structure composed of the following fields:

- ```.trialNumber```: [Integer]: A simple index of trial number by position. This value is not directly
utilized by the computeSDO code, and may be overridden.


!!! notes "IMPORTANT NOTES"
    - **xtData** is a homogeneous structure. During data population, the row index for each trial should be consistent across the entire data cell. (e.g. ‘signal 3’ on row 3 in trial 1 should also be on row 3 of trial 10).
    - Events which do not occur during a trial should still be given a field (and ‘time’ field left empty) to thus maintain this homogenous data structure.
    - Additional fields may be incorporated into the first row of **xtData** (primary data) array, however, these will not be used for SDO analysis, nor passed to the sdo structure.
    - Additional fields may be incorporated into the second row of **xtData** (metadata) array. These fields will be passively passed to the sdo structure. This permits an investigator to pass trial-wise notes, annotation, and data pre-processing parameters into the sdo structure for later comparison or review.

---

Due to the plurality of possible data formats and structures, a single method for populating xtData from user data structures is not defined. Users will need to write a solution which navigates this process. An example of one potential data format (structure array) into xtData is given below.


~~~
%// load 1xN structure with fields ‘signal’, ‘channelName’, ‘Hz’
>> ourEmgData = load(‘emgdata.mat’);

>> numberTrials = 20;
>> numberEmg = 8;

for tr = 1:numberTrials
    for m = 1:numberEmg
        %// populate xtData;
        emgName = ourEmgData(m).channelName;
        xtData{1,tr}(m).electrode = emgName;
        xtData{1,tr}(n).envelope = abs(ourEmgData(m).signal);
        sigLen = length(xtData{1,tr}(m).envelope);
        fs = ourEmgData(m).Hz; %// signal frequency
        xtData{1,tr}(n).fs = fs;
        %// Here, assume data signal is contiguous
        xtData{1,tr}(n).times = [1/fs:1/fs:sigLen/fs]’;
    end
end
~~~

!!! notes 
    - Time series data passed to the ```.envelope``` field should be in a [1xN] (row vector) format.
    - Time data contained in the ```.times``` field should be in a [1xN] (row vector) format.
    - Currently, frequency data, ```.fs```, is assumed to be constant over all trials and observations.

### 3. Populate ppDataHolder (ppData) Structure

You will need to write a (minimal) amount of code to populate the _ppDataHolder_ structure with _your_ specific data structure. 

---
**ppData**: A {2 x N_TRIALS} Cell array containing point-process observations collected during recording trials. Each trial is represented as a column of the cell array. SDO Analysis assumes a level of stationarity to the signal; that different trials differ in time, but not in principle signal behavior.

**ppData{1,:}** Each cell in the first row contains primary data within 1 x N_PP_CHANNELS struct. This
struct contains the following fields:

- ```.electrode```: A string or character unique identifier corresponding to this point-process data channel.
- ```.time```: A [1 x N] (Row) Vector containing the event times for the given point-process. These time points should be in the same units and relative start time as the data in the xtData against which it will be compared.
- ```.counts```: An integer count of the number of elements in ```.time```

**ppData{2,:}**: Each cell in the second row contains metadata associated with each trial. This data will be passively appended to the sdo structure later, to keep track of associated pre-processing parameters associated with SDO generation. It is a structure composed of the following fields:

- ```.trialNumber```: [Integer]: A simple index of trial number by position. This value is not directly
utilized by the computeSDO code, and may be overridden.
---

!!! notes "Important Notes"
    - ppData is a homogeneous structure. During data population, the row index for each trial should be consistent across the entire data cell. (e.g. ‘Neuron 3’ on row 3 in trial 1 should also be on row 3 of trial 10).
    - Events which do not occur during a trial should still be given a field (and ‘time’ field left empty) to thus maintain this homogenous data structure.
    - Additional fields may be incorporated into the first row of ppData (primary data) array, however, these   will not be used for SDO analysis, nor passed to the sdo structure.
    - Additional fields may be incorporated into the second row of ppData(metadata) array. These fields will be passively passed to the sdo structure. This permits an investigator to pass trial-wise notes, annotation, and data pre-processing parameters into the sdo structure for later comparison or review.


Due to the plurality of possible data formats and structures, a single method for populating ppData from user data structures is not defined. Users will need to write a solution which navigates this process. An example of one potential data format (structure array) into ppData is given below.

~~~
%// load Nx1 cell array of spike times;
>> ourSpikeData = load(‘spikedata.mat’);
>> numberTrials = 20;
>> numberNeurons = 10;
for tr = 1:numberTrials
    for n = 1:numberNeurons
        %// populate ppData;
        neuronName = strcat(‘neuron’, num2str(n));
        ppData{1,tr}(n).electrode = neuronName;
        ppData{1,tr}(n).time = ourSpikeData{n};
        ppData{1,tr}(n).counts = length(ppData{1,tr}(n).time);
    end
end


!!! notes
    - Ideally, sets of spike times passed to the .time field of the ppDatafield should be represented as a [1 x numberSpikes] *row* vector.
    - The units of time used in the ppData should match those used in xtData.

~~~

### 4. Validate dataholders (Optional)

If you are not confident in your code, or your input data structures are not homogenously passed through to the dataHolder structures, you can use the validation script [SAT.validateDataHolders](../functions/m_SAT_validateDataHolders.md). 

~~~
SAT.validateDataHolders(xtData, ppData, FIX_FLAG)
~~~


### 5. Generate an xtDataCell from xtData
~~~
$ xtdc = xtDataCell;
$ xtdc.import(xtData); %original xtData format;
~~~

### 6. Assign xtDataCell state-mapping parameters, if necessary;
~~~
$ xtdc.discretize()
~~~

Qualitatively validate discretization schema.
~~~
$ xtdc.plot(1:22, 1:11, [], 'stateSignal');
%// plot trials 1-22, rows 1-11, using the ‘stateSignal’
~~~

!!! tip
    - Adjust parameters of interest until the discretized data captures the phenomenon of interest (i.e. state definitions are sufficient to describe physiological signal)
    - Alternatively, check out the _SDO Parameter Explorer App_

### 7. Generate a ppDataCell class, and import from ppData

~~~
$ ppdc = ppDataCell;
$ ppdc.import(spikeTimeCell); %original ppData format
~~~

### 8. Shuffle spike occurrences in ppDataCell
~~~
$ ppdc = ppdc.shuffle
~~~
_This step is only specifically necessary if you want to validate the shuffle independently; if ppdc is not shuffled, it will be shuffled during compute_

### 9. Generate an instance of the sdoMultiMat class
~~~
smm = sdoMultiMat(); 
~~~

### 10. Adjust relevant parameters of the sdoMultiMat. 
!!! tip
    It's worthwhile to first understand what these parameters do. 


### 11. Import Data + Compute SDOs.  
~~~
smm.compute(xtdc, ppdc); 
~~~

Here, we both import data + compute SDOs. 

There are alternative options to the compute step with the sdoMultiMat. If you want to perform background subtraction, for instance, you could perform: 

~~~
smm.compute(xtdc, ppdc, 'backgroundSubtraction', 1); 
~~~

### 12. Find Significant SDOs. 
Here, you can screen for significant spike-triggered SDOs (defined as substantially different from the populated of shuffled-time null SDOs) across a number of tests. 

This step will let you short-list for interesting SDOs by performing these tests and generating a table. 

~~~
smm.findSigSdos(); 
~~~
!!! tip
    If this is called without additional parameters, it uses a pVal as defiend within the sdoMultiMat property smm.sigPVal. 

This method will populate the property ```smm.sigMat```. Within this property will be a table listing the xtdc and ppdc channel IDs for significant neurons, and the number of significant tests. 

### 13. Plot Significant SDOs of interest. 
Using the channel IDs, as above, use the plot method to visualize the SDOs. 

~~~
smm.plot(XT_CH_ID, PP_CH_ID) 
~~~
(Here, substituting ```XT_CH_ID``` and ```PP_CH_ID``` with actual numbers). 

### 14. Test predictive efficacy of significant SDOs. 

Use the 'getPredictionError` method to extract an instance of the [predictionError](../classes/m_predictionError.md) class. 
~~~
pe = smm.getPredictionError(xtdc, ppdc, XT_CH_ID, PP_CH_ID)
~~~
(Here, again, substituting ```XT_CH_ID``` and ```PP_CH_ID``` with integer indices). 

The instance of the [predictionError](../classes/m_predictionError.md) class directly contains the prediction error deviation in tabular form. If you want to visualize the prediction Error, you can plot it directly. 

~~~
pe.plot(); 
~~~

This will generate a number of plots which are helpful for inuiting the prediction using the various fit SDOs. 