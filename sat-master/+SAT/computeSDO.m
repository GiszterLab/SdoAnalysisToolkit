%% computeSDO
% Standalone programmatic script for SDO Analysis. Generates and analyzes the sdo
% structure  from the supplied xtData, ppData, and specified parameters.
% (Parameters must be adjusted within script body.)
% 
% DEPENDENCIES: pxTools Library
%
% INPUTS: 
%   xtData  - (Loaded into Memory)
%   ppData  - (Loaded into Memory); 
% 
% OUTPUTS: 
%   sdo     - (loaded into Memory)
%
% HEADER PARAMETERS; 
%   xtDataName : String/Char matching a xtData structure loaded
%       into memory. (Allows for variable naming); 
%       - Default = 'xtData'
%   ppDataName : String/Char matching a ppData structure loaded 
%       into memory. (Allows for variable naming); 
%       - Default = 'ppData'
%   XT_DATA_FIELD : String/Char matching the fieldname of the xtData
%       structure containing the time series data. 
%       - Default = 'envelope'; 
%   XT_ID_FIELD  :  String/Char matching the fieldname of the xtData
%       structure containing the unique channel identifier (name/ID)
%       - Default = 'electrode'
%   PP_ID_FIELD   : String/Char matching the fieldname of the ppData
%       structure containing the unique channel identifier (name/ID)
%       - Default = 'electrode'
%   XT_MAX_MODE   : String/Char matching a defined method for determining
%       the maximum value for state. Currently only 'xTrialxSeg' is
%       supported. 
%   XT_MAP_METHOD : String/Char Derivation of signal states from signal amplitude.
%       % - 'log'   : Equal intervals of log-transformed signal amplitude
%           (default)
%       % - 'linear': Equal intervals of non-transformed signal amplitude
%   N_BINS    : Integer. The number of signal bins/ states to break up
%       signal amplitude into. This value can be dropped to reduce memory
%       allocation at the cost of resolution. 
%       % - Default = 20; 
%   PX0_DURA_MS: Double. Duration of pre-spike interval to draw from xtData.
%       Should be an integer multiple of xtData sample period.
%   PX1_DURA_MS: Double. Duration of post-spike interval to draw from
%       xtData. Should be an integer multiple of xtData sample period. 
%   PX_FSM_WID:  Integer: Width of the smoothing kernel (numerator) of
%       drawn probability distributions. 
%       - Default = 1
%       - If PX_FSM_WID = 0, no smoothing; 
%   PX_FSM_STD:  Double: Normalization for smoothing kernel (denominator)
%       of drawn probability distributions
%       - Default = 1, 
%       - If PX_FSM_STD = 0, no smoothing; 
%   PX_NSHIFT:  Integer: Bin position of the start of the px1 distribution
%       relative to spike position. Horizontally translates px0 and px1
%       bins in time. 
%       - Default = 1; 
%   PX_ZDELAY:  Integer: Number of bins between the end of px0 distribution
%       and start of px1 distribution. 
%       - Default = 0; 
%   N_SHUFF:    Integer: Number of random draws of spiketime for
%       null-hypotheses SDOs. 
%       - Default = 1000; 
%   SHUFF_METHOD: {'ISI'/'CIF'}: Method for resampling spiketimes. 
%       ISI shuffles interspike intervals. CIF resamples from an estimated
%       conditional intensity function (CIF). 
%       - Default = 'ISI'
%   CIF_FIR_TYPE: {'sg', '-hg', 'expd', tb'}: Finite Impulse Response (FIR)
%       of spike impulses for estimating the CIF. Symmetrical Gaussian
%       ('sg'), negative half-gaussian ('-hg'), exponetial decay ('expd'),
%       trailing boxcar ('tb')
%       - Only used if SHUFF_METHOD == 'CIF'
%       - Default = '-hg' (negative half-gaussian')
%   CIF_TAU_SEC: Double: Decay rate for CIF_FIR_TYPE, in seconds. 
%       - if CIF_FIR_TYPE = {'sg', '-hg'}; duration for 1 STD, in Sec. 
%       - if CIF_FIR_TYPE = 'expd'; = 1/Lambda
%       - if CIF_FIR_TYPE = 'tb'; Duration for boxcar
%       - Default = 0.05 (50 ms)
%   SIG_PVAL:   Double: P-Value Threshold for significance. 
%       - Default = 0.05; 
%   Z_SCORE:  Boolean [0/1]
%       - If 1, z-transform measurements prior to stat. 
%   MAX_PP_PER_CHUNK: Integer. Maximum number of ppData channels to
%       populate sdo struct for at once. If memory issues occur, drop this
%       value. 
%       - Default = 25; 
%   MAX_XT_PER_CHUNK: Integer. Maximum number of xtData channels to
%       populate sdo struct for at once. If memory issues occur, drop this
%       value. 
%       - Default = 15; 
%   REBUILD_ARRAY: Logical: Restart sdo generation chunkwise. Set to 1 if
%       issues occur with resuming computeSDO after failure. 
%       - Default = 0; 
%   SAVE_SDO: Logical: After computing sdo matrix and running statistics,
%       save the data structure. 
%       - Default = 1; 
%   STEPWISE_CAL: Logical: Whether to estimate the SDO from the change of
%       markov between values dT apart in pre/post spike time bins. 
%       - Default = 0; 
%   VERBOSE: Logical: Use extended progress reporting on SDO calculation. 
%       - Default = 1; 

%_______________________________________
% Copyright (C) 2023 Trevor S. Smith
% Drexel University College of Medicine
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%__________________________________________


%% Static Primary Parameters
xtDataName  = 'emgCell';        %['emgCell'/'forceDataCell'/'moduleDataCell', etc] variable name for timeseries covariate data 
ppDataName  = 'spikeTimeCell';  %['spikeTimeCell'/ ... stimCell, etc] variable name for point-process data; 
%__ DataCell Variables
XT_DATA_FIELD   = 'envelope'; 
XT_ID_FIELD     = 'sensor'; 
PP_ID_FIELD     = 'sensor'; 
%__ State Assignment Vars
XT_MAX_MODE     = 'xTrialxSeg'; 
XT_MAP_METHOD   = 'log';
N_BINS          = 20;
%__ Probability Distribution Vars
%PX0_DURA_MS     = 0.5; 
PX0_DURA_MS     = 10; 
PX1_DURA_MS     = 10; 
PX_FSM_WID      = 0;    %// Not used if 'STEPWISE_CALC' = 1; 
PX_FSM_STD      = 0;    %// Not used if 'STEPWISE_CALC' = 1; 
PX_NSHIFT       = 1;    %// Not used if 'STEPWISE_CALC' = 1; 
PX_ZDELAY       = 0;    %// Not used if 'STEPWISE_CALC' = 1; 
%__ SDO Generation Vars
N_SHUFF         = 1000;  
SHUFF_METHOD    = 'ISI'; %{'ISI'/'CIF'}
CIF_FIR_TYPE    = '-hg'; %{'sg', '-hg', 'expd', 'tb'}; 
CIF_TAU_SEC     = 0.05; % 
%__ SDO Analysis Vars
SIG_PVAL        = 0.05;  
Z_SCORE         = 1;
%__ Execution Vars
MAX_PP_PER_CHUNK    = 25; 
MAX_XT_PER_CHUNK    = 15; 
REBUILD_ARRAY       = 0; 
SAVE_SDO            = 0; 
STEPWISE_CALC       = 0; %[0/1] Stepwise (V.2) Algorithm 
VERBOSE             = 1; 

%% Ensure Data present, else Find Data
if ~exist('xtData', 'var') || ~exist('ppData', 'var')
    try
        xtData = eval(xtDataName); 
        ppData = eval(ppDataName); 
    catch
        disp("xtData or ppData not passed!"); 
    end
end
%% Derived Secondary Parameters
if isfield(xtData{1,1}, 'fs')
    XT_HZ = xtData{1,1}.fs; 
else
    XT_HZ           = 2000; %find or define
end

N_TRIALS        = size(xtData,2); 
N_PX0_PTS       = round(PX0_DURA_MS*XT_HZ/1000); 
N_PX1_PTS       = round(PX1_DURA_MS*XT_HZ/1000); 

N_PP_CHANNELS   = length(ppData{1,1}); 
N_XT_CHANNELS   = length(xtData{1,1}); 
N_PP_CHUNKS     = ceil(N_PP_CHANNELS/MAX_PP_PER_CHUNK); 
N_XT_CHUNKS     = ceil(N_XT_CHANNELS/MAX_XT_PER_CHUNK); 

%% Statemap xtData

[~, xtData] = pxTools.getXtStateMap(xtData, N_BINS,...
     'fieldname', XT_DATA_FIELD, 'mapMethod', XT_MAP_METHOD, 'maxMode', XT_MAX_MODE); 

%% Compute SDO 

if (N_PP_CHUNKS == 1) && (N_XT_CHUNKS == 1)
    if STEPWISE_CALC ==1
        sdo = SAT.compute.populateSDOArray_stepwise(xtData, ppData,...
            [N_PX0_PTS, N_PX1_PTS], ...
            'xtIDField', XT_ID_FIELD, 'ppIDField', PP_ID_FIELD, ...
            'fieldName', XT_DATA_FIELD, ...
            'nShuffles', N_SHUFF, ... 
            'shuffMethod', SHUFF_METHOD, ...
            'CIF_FIR', CIF_FIR_TYPE, ...
            'CIF_TAU', CIF_TAU_SEC, ...
            'verbose', VERBOSE);            
    else
        sdo = SAT.compute.populateSDOArray(xtData, ppData,...
            [N_PX0_PTS, N_PX1_PTS], ...
            'xtIDField', XT_ID_FIELD, 'ppIDField', PP_ID_FIELD, ...
            'fieldName', XT_DATA_FIELD, ...
            'pxFilter', [PX_FSM_WID, PX_FSM_STD], ...
            'pxShift',  PX_NSHIFT, 'pxDelay', PX_ZDELAY, ...
            'nShuffles', N_SHUFF, ... 
            'shuffMethod', SHUFF_METHOD, ...
            'CIF_FIR', CIF_FIR_TYPE, ...
            'CIF_TAU', CIF_TAU_SEC, ...
            'verbose', VERBOSE);
    end
else
    %// build chunkwise, continuining after an error, if necessary
    if (~exist('sdoChunkArr', 'var')) || REBUILD_ARRAY 
        %// only reset on first run, or if requested
        sdoChunkArr = cell(N_XT_CHUNKS, N_PP_CHUNKS);
        xtChRng0 = 1; 
        ppChRng0 = 1; 
    end
    for m = xtChRng0:N_XT_CHUNKS
        if VERBOSE == 1
            disp(strcat("Beginning Chunk ", num2str(m), "/", num2str(N_XT_CHUNKS))); 
        end
        xtRange0 = (m-1)*MAX_XT_PER_CHUNK+1; 
        xtRange1 = min( m*MAX_XT_PER_CHUNK, N_XT_CHANNELS);
        minixtData  = cell(2, N_TRIALS); 
        for tr=1:N_TRIALS
            minixtData{1,tr} = xtData{1,tr}(xtRange0:xtRange1);  
        end
        for u = ppChRng0:N_PP_CHUNKS
            ppRange0 = (u-1)*MAX_PP_PER_CHUNK+1; 
            ppRange1 = min( u*MAX_PP_PER_CHUNK, N_PP_CHANNELS); 
            minippData  = cell(2,N_TRIALS); 
            for tr = 1:N_TRIALS
                minippData{1,tr} = ppData{1,tr}(ppRange0:ppRange1); 
            end
            if STEPWISE_CALC == 1
                sdoChunkArr{m,u} = SAT.compute.populateSDOArray_stepwise( ...
                    minixtData, minippData,...
                    [N_PX0_PTS, N_PX1_PTS], ...
                    'xtIDField', XT_ID_FIELD, 'ppIDField', PP_ID_FIELD, ...
                    'fieldName', XT_DATA_FIELD, ...
                    'nShuffles', N_SHUFF, ... 
                    'shuffMethod', SHUFF_METHOD, ...
                    'CIF_FIR', CIF_FIR_TYPE, ...
                    'CIF_TAU', CIF_TAU_SEC, ...
                    'verbose', VERBOSE);
            else      
                sdoChunkArr{m,u} = SAT.compute.populateSDOArray(minixtData, minippData, ...
                    [N_PX0_PTS, N_PX1_PTS], ...
                    'xtIDField', XT_ID_FIELD, 'ppIDField', PP_ID_FIELD, ...
                    'fieldName', XT_DATA_FIELD, ...
                    'pxFilter', [PX_FSM_WID, PX_FSM_STD], ...
                    'pxShift',  PX_NSHIFT, 'pxDelay', PX_ZDELAY, ...
                    'nShuffles', N_SHUFF, ...
                    'shuffMethod', SHUFF_METHOD, ...
                    'CIF_FIR', CIF_FIR_TYPE, ...
                    'CIF_TAU', CIF_TAU_SEC, ...
                    'verbose', VERBOSE);    
            end
            ppChRng0 = u; %// update start index on successes
        end
        xtChRng0 = m; 
        ppChRng0 = 1; %reset w/ start index on successful row
    end
    
    [sdo] = SAT.sdoUtils.mergeSDOChunkArray(sdoChunkArr); 
    
    %_________
    clear sdoChunkArr xtChRng0 xtRange0 xtRange1 ppChRng0 ppChRng1 
    clear minixtData minippData 
end
    
%% Compute SDO Statistics/Significance
sdo = SAT.compute.performStats(sdo); 

%// analyze sdos-stats at selected significance; 

sdo = SAT.compute.testStatSig(sdo, SIG_PVAL, Z_SCORE); 

%% Append Processing Parameters
%// Intentional Parallelism
params.xt.xtDataName            = xtDataName; 
params.xt.DataFieldname         = XT_DATA_FIELD; 
params.xt.IDFieldname           = XT_ID_FIELD; 
params.xt.MapMethod             = XT_MAP_METHOD; 
params.xt.MaxMode               = XT_MAX_MODE; 
%
params.pp.ppDataName            = ppDataName; 
params.pp.IDFieldname           = PP_ID_FIELD; 
%
params.px.px0DurationMs         = PX0_DURA_MS; 
params.px.px1DurationMs         = PX1_DURA_MS; 
params.px.smoothingFilterWidth  = PX_FSM_WID; 
params.px.smoothingFilterStd    = PX_FSM_STD; 
params.px.x1StartShift          = PX_NSHIFT; 
params.px.x0x1Delay             = PX_ZDELAY; 
%
%_______ Trialwise Metadata; 
% --> Because we do not control this field, passively pass the elements

if size(xtData,1) > 1
    params.xt.trialwiseMetadata     = xtData(2,:); 
end
if size(ppData,1) > 1
    params.pp.trialwiseMetadata     = ppData(2,:); 
end

for m=1:N_XT_CHANNELS
    sdo(m).params = params; 
end

%% Save Module

%// Finally, writeout sdo matrix to analysis position, if desired; 

if SAVE_SDO == 1
    savePath = uigetdir([], "Where should the SDO matrix Structure be saved?"); 
    ffile = fullfile(savePath, 'sdo.mat'); 
    save(ffile, 'sdo', '-v7.3'); 
end

%% Varspace Clean-up

clear exitFlag m MAX_PP_PER_CHUNK MAX_XT_PER_CHUNK N_PP_CHUNKS ffile
clear N_PP_CHANNELS N_PX0_PTS N_PX1_PTS N_SHUFF N_TRIALS N_XT_CH
clear N_XT_CHANNELS N_XT_CHUNKS N_BINS params PP_ID_FIELD ppDataName
clear PX0_DURA_MS PX1_DURA_MS PX_FSM_STD PX_FSM_WID PX_NSHIFT
clear PX_ZDELAY REBUILD_ARRAY SAVE_SDO savePath SIG_PVAL XT_DATA_FIELD
clear XT_HZ XT_ID_FIELD XT_MAP_METHOD XT_MAX_MODE xtDataName
clear STEPWISE_CALC SHUFF_METHOD CIF_FIR_TYPE CIF_TAU_SEC VERBOSE Z_SCORE

