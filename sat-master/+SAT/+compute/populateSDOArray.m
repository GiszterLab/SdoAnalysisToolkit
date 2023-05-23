%% computeSDO_populateSDOArray
% Given supplied point-process and time series data sets, compute the
% stochastic dynamic operator for every supplied combination. 
%
% The SDO measures the (change in) average state transition between each time
% bin in the 'pre-spike' interval to each 'post-spike' time bin; averaged
% over all spiking events. 
%
% PREREQUSITE: xtDataCell has been processed by 'createXtStateMap.m'; to
% provide for signal levels for assigning discrete states
%
% INPUT PARAMETERS: 
%   xtDataCell : A {2, #Trials} cell; each element containing a field
%       'signalLevels' and a field with the data to assign. 
%   ppDataCell : (Optional ??) A {2, #Trials} cell; Each element of the first row 
%       contains a structure with fields ('time') ; elements in the second 
%       row contain metadata for processing parameters of point process Data.
%       - If not passed, only evaluate background SDO into 'sdo' structure
%   pxNPoints : [#PointsPrior, #PointsPoint]
%       - Number of points to use relative to time index to collect state
%       over before (first val) or after (second val) the reference time
%       - If not left empty, defaults to [20 20]; 
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


%%
function [sdo] = populateSDOArray(xtData, ppData, pxNPoints, varargin)
p = inputParser; 
addParameter(p, 'xtIDField', 'electrode'); 
addParameter(p, 'ppIDField', 'electrode'); 
addParameter(p, 'fieldName', 'envelope'); 
addParameter(p, 'ppDataField', 'time'); 
addParameter(p, 'pxFilter', [1,1]); 
addParameter(p, 'pxShift',  1, @isscalar); 
addParameter(p, 'pxDelay', 0, @isscalar);
addParameter(p, 'nShuffles', 1000, @isscalar);
addParameter(p, 'shuffMethod', 'ISI'); 
addParameter(p, 'verbose', 0); 
%__ CIF_Reshuffle-specific Parameters
addParameter(p, 'CIF_FIR', '-hg'); 
addParameter(p, 'CIF_TAU', 0.05, @isscalar); 

parse(p, varargin{:}); 
pR = p.Results; 
%//Primary Params
N_SHUFF         = pR.nShuffles; 
SHUFF_METHOD    = pR.shuffMethod; 
CIF_FIR         = pR.CIF_FIR; 
CIF_TAU         = pR.CIF_TAU; 
SFIELD          = pR.fieldName;
PP_DATAFIELD    = pR.ppDataField; 
XT_ID_FIELD     = pR.xtIDField; 
PP_ID_FIELD     = pR.ppIDField;
PX_FSM_WID      = pR.pxFilter(1);   
PX_FSM_STD      = pR.pxFilter(2); 
PX_NSHIFT       = pR.pxShift; 
PX_ZDELAY       = pR.pxDelay; 
VERBOSE         = pR.verbose; 

if ~isempty(pxNPoints)
    N_PX0_PTS = pxNPoints(1); 
    N_PX1_PTS = pxNPoints(2); 
elseif length(pxNPoints) == 1
    N_PX0_PTS = pxNPoints(1); 
    N_PX1_PTS = pxNPoints(1); 
else
    N_PX0_PTS = 20; 
    N_PX1_PTS = 20; 
end

%// Derivative Params
N_BINS          = length(xtData{1,1}(1).signalLevels) - 1; 
N_TRIALS        = size(xtData,2);
N_PP_CHANNELS   = length(ppData{1,1});  
N_XT_CHANNELS   = length(xtData{1,1}); 
XT_HZ           = xtData{1,1}(1).fs; 

%% PreCastArr

[sdo] = SAT.compute.sdoStruct_new(N_XT_CHANNELS); 
                
%%
shuffSpikeCell = cell(N_PP_CHANNELS, N_TRIALS); 
shuffRasterCell= cell(N_PP_CHANNELS, N_TRIALS); 

for tr=1:N_TRIALS
    for u=1:N_PP_CHANNELS
        n_obs_tr_spikes = length(ppData{1,tr}(u).(PP_DATAFIELD)); 
        if n_obs_tr_spikes > 1
            switch SHUFF_METHOD 
                case {'ISI', 'isi'}
                    %// Original Method
                    firstSpikeTime = ppData{1,tr}(u).(PP_DATAFIELD)(1); 
                    lastSpikeTime  = ppData{1,tr}(u).(PP_DATAFIELD)(end); 
                    shuffSpikeCell{u,tr} = shuffleSpikesInsideRange(ppData{1,tr}(u).(PP_DATAFIELD), firstSpikeTime, lastSpikeTime, N_SHUFF); 
                case {'CIF', 'cif'}
                    %// Derive null hypotheses from CIF of prespike intervals.
                    shuffSpikeCell{u,tr} = cifReshuffle(ppData{1,tr}(u).(PP_DATAFIELD), XT_HZ, N_SHUFF, CIF_TAU, 'method', CIF_FIR); 
            end
        else
            shuffSpikeCell{u,tr} = repmat(ppData{1,tr}(u).time, N_SHUFF, 1); 
        end
        shuffRasterCell{u,tr}= round(shuffSpikeCell{u,tr}* XT_HZ);
    end
end

%% Observed Spikes

%// nUnits x nTrials cells
[obsPxt0Cell, obsPxt1Cell] = pxTools.getTrialwisePxt( ...
        xtData, ppData, ...
        'xtDataField', SFIELD,...
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
            1:N_TRIALS, m, ...
            'xtDataField', SFIELD,...
            'pxNPoints', [N_PX0_PTS, N_PX1_PTS], ...
            'pxFilter',  [PX_FSM_WID,PX_FSM_STD], ...
            'pxShift',   PX_NSHIFT, ...
            'pxDelay',   PX_ZDELAY); 
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
        nTotalSpikesUsed = 0; 
        for tr = 1:N_TRIALS
            nTrialSpikes = size(shuffRasterCell{u,tr},2); 
            if nTrialSpikes < 1
                continue
            end
            flatTrShuffSpikes = reshape(shuffRasterCell{u,tr}, 1, nTrialSpikes*N_SHUFF); 
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
            nTotalSpikesUsed    = nTotalSpikesUsed  + nTrialSpikes; 
        end
        %// compute average effects
        if nTotalSpikesUsed == 0 
            %// avoid divide by 0
            nTotalSpikesUsed = 1; 
        end
        sdo(m).sdos{1,u}                = unitDeltaSDO/nTotalSpikesUsed;   
        sdo(m).sdosJoint{1,u}           = unitJointSDO/nTotalSpikesUsed;     
        sdo(m).shuffles{u}.SDOShuff     = unitShuffDeltaSDO/nTotalSpikesUsed; 
        sdo(m).shuffles{u}.SDOJointShuff= unitShuffJointSDO/nTotalSpikesUsed;
        % __ Release memory
        clear unitJointSDO unitDeltaSDO unitShuffDeltaSDO unitShuffJointSDO
        clear trShuffDeltaSDO trShuffJointSDO
    end
    sdo(m).bkgrndJointSDO   = bkgdJointSDO; 
    sdo(m).bkgrndSDO        = bkgdDeltaSDO;  
    %
    try
        sdo(m).signalType       = xtData{1,1}(m).(XT_ID_FIELD); 
    catch
        disp("No fieldnames recorded for timeseries data"); 
    end
    try
        sdo(m).neuronNames      = {ppData{1,1}(:).(PP_ID_FIELD)}; 
    catch
        disp("No fieldnames recorded for point process data"); 
    end
    sdo(m).levels           = xtData{1,1}(m).signalLevels; 
    sdo(m).unit             = '%'; 
    toc 
    if VERBOSE == 1
        disp(strcat("Finished Ch#",  num2str(m), "/", num2str(N_XT_CHANNELS))); 
    end
end

end
                