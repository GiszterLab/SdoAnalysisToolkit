%% computeSDO_populateSDOArray
% Given supplied point-process and time series data sets, compute the
% stochastic dynamic operator for every supplied combination. 
%
% Hardfork update to actually pass in the xtDataCell and ppDataCell classes
% directly; making the evaluation more straightforward and function-calls
% cleaner, and hopefully more efficient. 
%
% The SDO measures the (change in) average state transition between each time
% bin in the 'pre-spike' interval to each 'post-spike' time bin; averaged
% over all spiking events. 
%
% PREREQUSITE: xtDataCell has been processed by 'createXtStateMap.m'; to
% provide for signal levels for assigning discrete states
%
% INPUT PARAMETERS: 
%   xtDataCell : 
%   ppDataCell : 
%
% OPTIONAL NAME-VALUE PAIRS: 
%   'fieldname': (character array)
%       - Field from xtDataCell containing time series data; 
%       - Default 'envelope'; 
%   'pxFilter': [#States Width, #States Standard Deviation]
%       - Gaussian Filtering Parameters for smoothing prespike/postspike
%       distributions. Smoothing may violate assumptions of SDO linearity. 
%       - If set to [0,0], do not filter distributions; 
%       - Default: [1,1]; 
%   'pxShift': [Integer]
%       - Where the split between prespike and postspike distributions are
%       defined relative to reference time point (0); 
%       - Default = 1; (reference point terminal value of prespike dist)
%   'pxDelay': [Integer]
%       - Number of time bins between the end of 'prespike' and beginning
%       of 'postspike' distributions; 
%       - Default = 1; 
%   'nShuffles': [Integer]
%       - Number of reshuffles of spike ISIs to use for statistical control
%       on each neuron. 
%       - Default = 1000;
%   'shuffMethod': {'ISI'/'CIF'}
%       - Whether to generate shuffled spikes from the interspike intervals
%       of observed spikes (ISI) or a conditional intensity function (CIF)
%       from the spike process directly. 
%       - Default = 'ISI'
%   'CIF_FIR': {'sg', '-hg', 'expd', 'tb'}
%       - Selection between one of the currently supported FIRs for
%       shuffling spiketimes: 
%       Symmetrical gaussian ('sg'), negative half-gaussian ('-hg'),
%       exponential decay ('expd'), trailing boxcar ('tb')
%       - Default = '-hg'
%   'CIF_TAU': [Double]
%       - The decay rate for the filter function/ finite impulse response
%       for estimating the CIF (in Sec). Corresponds to duration for 1 STD 
%       of gaussian FIRs, or 1/Lamda for exponential decay FIRs. 
%       - Default = 0.05 (50 ms); 
%   'verbose': [0/1]
%       - Whether to use long form (1) or short form (0) status reporting.
%       - Default = 0. 
%
% OUTPUT: 
%   'sdo': a 1*#XtChannels structure with fields; 
%       - 'signalType'  : XtChannelName
%       - 'levels'      : State signal maping levels
%       - 'unit'        : 
%       - 'sdosJoint'   : Spike-triggered Px0*Px1 Joint Distribution Matrix
%       - 'sdos'        : Spike-triggered change in px around px0*px1; 
%       - 'bkgrndJointSDO' : channelwise Px0*Px1; 
%       - 'bkgrndSO'    : channelwise change in Px0*Px1; 
%       - 'neuronName   : PP Unit names
%       - 'stats'       : contains statistical information and shuffles

% NOTE: The version 3 algorithm used here is optimized, so that the
% calculation of the SDO is not directly between each time bin in pre-spike
% to each time bin in post-spike. Because it the effects are averaged, the
% average transition over all bins (states) is the transition to the average
% of the state bins (i.e. post-spike distribution). Because the effects of
% pre-spike time bins are averaged over all time bins, the average
% pre-->post spike effect is the average of the pre to the average of the
% post; i.e. distribution --> distribution. 

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

% 12.4.2023 - Added in the STIRPD (spike-triggered impulse response
% probability distribution) as a standard call. 

%%
function [sdo] = populateSDOArray2(xtdc, ppdc, vars)
arguments
    xtdc xtDataCell
    ppdc ppDataCell
    vars.pxFilter       = [1,1]; 
    vars.px0nPoints     {mustBeInteger}= 20;
    vars.px1nPoints     {mustBeInteger} = 20; 
    vars.pxShift        {mustBeInteger} = 1; 
    vars.pxDelay        {mustBeInteger} = 0;
    vars.useTrials      = 1:ppdc.nTrials; 
    
    % __ Depreciated; uses the ppdc methods; 
    %vars.nShuffles      {mustBeInteger} = 1000; 
    %vars.shuffMethod    {mustBeMember(vars.shuffMethod, {'ISI', 'isi', 'CIF', 'cif'})} ='isi';  
    %vars.CIF_FIR        {mustBeMember(vars.CIF_FIR, {'sg', '-hg', 'expd', 'tb'})} = '-hg'; 
    %vars.CIF_TAU        {mustBeNonnegative} = 0.05; 
end

%Note that these are self-referential
% ___ 
N_SHUFF         = ppdc.nShuffles; 
SHUFF_METHOD    = ppdc.shuffMethod;  
CIF_FIR         = ppdc.shuffCIF; 
CIF_TAU         = ppdc.shuffTau; 
% ___ 

USE_TRIALS   = vars.useTrials; 
USE_CHANNELS = 1:ppdc.nChannels; 

PP_DATAFIELD = ppdc.dataField; 
XT_DATAFIELD = xtdc.dataField; 

PX_FSM_WID      = vars.pxFilter(1);   
PX_FSM_STD      = vars.pxFilter(2); 
PX_NSHIFT       = vars.pxShift; 
PX_ZDELAY       = vars.pxDelay; 
VERBOSE = 1; 

N_PX0_PTS = vars.px0nPoints; 
N_PX1_PTS = vars.px1nPoints; 

xtData = xtdc.data; 
ppData = ppdc.data; 

%// Derivative Params
N_BINS          = xtdc.nBins; 
N_TRIALS        = xtdc.nTrials; 
N_PP_CHANNELS   = ppdc.nChannels; 
N_XT_CHANNELS   = xtdc.nChannels; 

XT_HZ   = xtdc.fs; 

%% PreCastArr

[sdo] = SAT.compute.sdoStruct_new(N_XT_CHANNELS, N_PP_CHANNELS); 
                

%%
if ~ppdc.shuffledSpikes
    ppdc.shuffle; 
end

shuffRasterCell = ppdc.getRasterIndices(XT_HZ, 'dataField', 'shuffle'); 

%% Observed Spikes

% 
disp("Calculating STIRPDs"); 
tic
[obs_idx0, obs_idx1]    = ppdc.getPerieventIndices(USE_TRIALS, USE_CHANNELS,'fs', xtdc.fs, ...
    'n_shift',PX_NSHIFT,'t0_nPoints', N_PX0_PTS, 't1_nPoints',N_PX1_PTS, 'z_delay', PX_ZDELAY); 

for m = 1:N_XT_CHANNELS
    for u = 1:N_PP_CHANNELS
        obs_xv0     = xtdc.getValuesAtIndices(obs_idx0(u,:), 'useChannels', m, "dataField","stateSignal", 'useTrials', vars.useTrials);  
        obs_xv1     = xtdc.getValuesAtIndices(obs_idx1(u,:), 'usechannels', m, "dataField","stateSignal", 'useTrials', vars.useTrials); 
        cat_xv0         = cellhcat(obs_xv0); 
        cat_xv1         = cellhcat(obs_xv1);  
        sdo(m).stirpd{u} = pxTools.getStirpd(cat_xv0, cat_xv1, N_BINS); 
    end
end
toc

disp("Populating SDOs"); 
%// nUnits x nTrials cells
[obsPxt0Cell, obsPxt1Cell] = pxTools.getTrialwisePxt( ...
        xtData, ppData, ...
        vars.useTrials, 1:N_XT_CHANNELS, ...
        'xtDataField', XT_DATAFIELD,...
        'ppDataField', PP_DATAFIELD, ... 
        'pxNPoints', [N_PX0_PTS, N_PX1_PTS], ...
        'pxFilter',  [PX_FSM_WID,PX_FSM_STD], ...
        'pxShift',   PX_NSHIFT, ...
        'pxDelay',   PX_ZDELAY); 
%_____

for m = 1:N_XT_CHANNELS
    tic; 
    %// eval ALL points for a xt channel first, then lookup shuffle points
    [pxt0Cell, pxt1Cell] = pxTools.getTrialwisePxt(xtData, [], ...
            vars.useTrials, m, ...
            'xtDataField', XT_DATAFIELD,...
            'pxNPoints', [N_PX0_PTS, N_PX1_PTS], ...
            'pxFilter',  [PX_FSM_WID,PX_FSM_STD], ...
            'pxShift',   PX_NSHIFT, ...
            'pxDelay',   PX_ZDELAY); 
            %1:N_TRIALS, m, ...
    % ____
    %// background set once; constant; 
    bkgdDeltaSDO    = zeros(N_BINS, N_BINS);
    bkgdJointSDO    = zeros(N_BINS, N_BINS); 
    nTotalTrLength  = 0; 
    for tr = 1:N_TRIALS
        pxt0_Bkgd = pxt0Cell{1,tr}{m}; 
        pxt1_Bkgd = pxt1Cell{1,tr}{m}; 
        bkgdTrDeltaSDO = (pxt1_Bkgd*pxt0_Bkgd')-diag(sum(pxt0_Bkgd,2)); 
        bkgdTrJointSDO = (pxt1_Bkgd * pxt0_Bkgd');      
        %// iteratively update
        nTotalTrLength  = nTotalTrLength + size(pxt1_Bkgd,2); 
        bkgdDeltaSDO    = bkgdDeltaSDO + bkgdTrDeltaSDO; 
        bkgdJointSDO    = bkgdJointSDO + bkgdTrJointSDO;  
    end
    bkgdDeltaSDO = bkgdDeltaSDO/nTotalTrLength; 
    bkgdJointSDO = bkgdJointSDO/nTotalTrLength; 

    % __ Unitwise-Trialwise eval
    for u = 1:N_PP_CHANNELS
        unitDeltaSDO        = zeros(N_BINS, N_BINS); 
        unitJointSDO        = zeros(N_BINS, N_BINS); 
        unitShuffDeltaSDO   = zeros(N_BINS, N_BINS, N_SHUFF); 
        unitShuffJointSDO   = zeros(N_BINS, N_BINS, N_SHUFF); 
        for tr = 1:N_TRIALS
            nTrialSpikes = ppdc.nTrialEvents(u,tr); 
            if nTrialSpikes < 1
                continue
            end
            flatTrShuffSpikes = reshape(shuffRasterCell{u,tr}, 1, nTrialSpikes*N_SHUFF); 
            if any(flatTrShuffSpikes == 0)
                flatTrShuffSpikes(flatTrShuffSpikes == 0) = 1; 
            end

            %
            shuffUnitTrPx0 = pxt0Cell{1,tr}{m}(:,flatTrShuffSpikes); 
            shuffUnitTrPx1 = pxt1Cell{1,tr}{m}(:,flatTrShuffSpikes); 
            px0ShuffSS = reshape(shuffUnitTrPx0, N_BINS, nTrialSpikes, N_SHUFF); 
            px1ShuffSS = reshape(shuffUnitTrPx1, N_BINS, nTrialSpikes, N_SHUFF);
            %
            trShuffDeltaSDO = zeros(N_BINS, N_BINS, N_SHUFF); 
            trShuffJointSDO = zeros(N_BINS, N_BINS, N_SHUFF); 
            for ss = 1:N_SHUFF
                trShuffDeltaSDO(:,:,ss) = px1ShuffSS(:,:,ss)*px0ShuffSS(:,:,ss)'-diag(sum(px0ShuffSS(:,:,ss),2)); %V3
                trShuffJointSDO(:,:,ss) =  px1ShuffSS(:,:,ss) * px0ShuffSS(:,:,ss)'; 
            end               

            % __ 
            %// We are averaging the transitions from each time bin in the
            %pre-spike to each time bin in the post-spike, then averaging
            %over all spikes. Hence, the average effects may be derived
            %from the distributions of state
            %
            trDeltaSDO = (obsPxt1Cell{1,tr}{m,u}*obsPxt0Cell{1,tr}{m,u}')-diag(sum(obsPxt0Cell{1,tr}{m,u},2)); %V3
            trJointSDO =  obsPxt1Cell{1,tr}{m,u} * obsPxt0Cell{1,tr}{m,u}';            
            %// Iteratively update
            unitDeltaSDO        = unitDeltaSDO + trDeltaSDO; 
            unitJointSDO        = unitJointSDO + trJointSDO; 
            unitShuffDeltaSDO   = unitShuffDeltaSDO + trShuffDeltaSDO; 
            unitShuffJointSDO   = unitShuffJointSDO + trShuffJointSDO;
        end
        %// compute average effects
        nTotalSpikesUsed = sum(ppdc.nTrialEvents(u,USE_TRIALS)); 
        if nTotalSpikesUsed == 0 
            %// avoid divide by 0
            nTotalSpikesUsed = 1; 
        end
        sdo(m).sdos{1,u}                = unitDeltaSDO/nTotalSpikesUsed;   
        sdo(m).sdosJoint{1,u}           = unitJointSDO/nTotalSpikesUsed;     
        sdo(m).shuffles{u}.SDOShuff     = unitShuffDeltaSDO/nTotalSpikesUsed; 
        sdo(m).shuffles{u}.SDOJointShuff= unitShuffJointSDO/nTotalSpikesUsed;
        %
        sdo(m).stats{u}.nEvents = nTotalSpikesUsed; 
        % -- 

        % __ Release memory
        clear unitJointSDO unitDeltaSDO unitShuffDeltaSDO unitShuffJointSDO
        clear trShuffDeltaSDO trShuffJointSDO
    end
    sdo(m).bkgrndJointSDO   = bkgdJointSDO; 
    sdo(m).bkgrndSDO        = bkgdDeltaSDO;  
    sdo(m).signalType       = xtdc.sensor{m};
    sdo(m).neuronNames      = ppdc.sensor; 
    sdo(m).levels           = xtData{1,1}(m).signalLevels; 
    sdo(m).unit             = '%'; %reserved for future use
    toc 
    if VERBOSE == 1
        disp(strcat("Finished Ch#",  num2str(m), "/", num2str(N_XT_CHANNELS))); 
    end
end
end
                