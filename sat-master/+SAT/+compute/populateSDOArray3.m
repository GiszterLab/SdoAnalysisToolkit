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
%   'method'
%       - 'original' = (V3 Algo) 
%       - 'asymmetric' = (V5)
%       - 'optimized' = V7
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

% 2.2.2024 - Added the different algorithms for SDO estimation, and
% included the optional parfor in-parallel synchronization

% 7.20.2024 - Added the Constrained Optimization (V7) Algo as a possible
% method. 

%%
function [sdo] = populateSDOArray3(xtdc, ppdc, vars)
arguments
    xtdc xtDataCell
    ppdc ppDataCell
    vars.pxFilter       = [1,1]; 
    vars.px0nPoints     {mustBeInteger}= 20;
    vars.px1nPoints     {mustBeInteger} = 20; 
    vars.pxShift        {mustBeInteger} = 1; 
    vars.pxDelay        {mustBeInteger} = 0; 
    vars.useTrials      = 1:ppdc.nTrials; 
    vars.condenseShuffles {mustBeNumericOrLogical} = 0; % Only recommended with large datasets
    vars.method         {mustBeMember(vars.method, {'original', 'asymmetric', 'optimized'})} = 'original'; %'asymmetric'; 
    vars.maxBackgroundDraws = 10000; 
    %vars.maxBackgroundDraws = 10e9; 
    vars.parallelCompute = 0; 
   
end

%Note that these are self-referential
% ___ 
N_SHUFF         = ppdc.nShuffles; 
% ___ 

USE_TRIALS   = vars.useTrials; 
USE_CHANNELS = 1:ppdc.nChannels; 

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

% ___ Tuning; 
%asymmetry_type = 'final'; %'step'/'final'; 
asymmetry_type = 'step'; 

retainShuffles = 1; 

% ___ 

if vars.condenseShuffles
    disp("NOTE: Condensing Shuffles may greatly increase compute time."); 
end

nUseTrials = length(vars.useTrials); 


%% PreCastArr

[sdo] = SAT.compute.sdoStruct_new(N_XT_CHANNELS, N_PP_CHANNELS); 
                

%%
if ~ppdc.shuffledSpikes
    if ppdc.nShuffles > 0
        ppdc.shuffle;
    end
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
        %
        cat_xv0     = cellhcat(obs_xv0); 
        cat_xv1     = cellhcat(obs_xv1);  
        sdo(m).stirpd{u} = pxTools.getStirpd(cat_xv0, cat_xv1, N_BINS); 
    end
end
toc

disp("Populating SDOs"); 
%// nUnits x nTrials cells
[obsPxt0Cell, obsPxt1Cell] = pxTools.getTrialwisePxt( ...
        xtData, ppData, ...
        vars.useTrials, 1:N_XT_CHANNELS, ...
        'xtDataField', xtdc.dataField,...
        'ppDataField', ppdc.dataField, ... 
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
            'xtDataField', xtdc.dataField,...
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

        % ___ Avoid using data from trials we don't care about; 
        % 8.12.2024 Patch; 
        if ~ismember(vars.useTrials, tr)
            continue; 
        end


        pxt0_Bkgd = pxt0Cell{1,tr}{m}; 
        pxt1_Bkgd = pxt1Cell{1,tr}{m}; 

        bkgndLen = size(pxt1_Bkgd,2); 
        if bkgndLen > vars.maxBackgroundDraws 
            rand_idx = randi(bkgndLen, [1, vars.maxBackgroundDraws]);  
            bkgndLen = vars.maxBackgroundDraws; 
        else
            %// only a few number of samples for background; Take
            %everything; 
            rand_idx = 1:bkgndLen; 
        end

        switch vars.method
            
            case {'original', 'optimized'}%{'original'}%, 'asymmetric'}
                [bkgdTrDeltaSDO, bkgdTrJointSDO] = SAT.compute.sdo3(pxt0_Bkgd(:,rand_idx), pxt1_Bkgd(:,rand_idx), 0, ...
                    parallelCompute=vars.parallelCompute, rescale=false); 
                %
                % this is generally unnecessary if N_XT >> nSpikes; 
            case 'asymmetric'
                [bkgdTrDeltaSDO, bkgdTrJointSDO] = SAT.compute.sdo5(pxt0_Bkgd(:,rand_idx), pxt1_Bkgd(:,rand_idx), 0, ...
                    'asymmetry', asymmetry_type, ... 
                    parallelCompute=vars.parallelCompute, rescale=false); 
                %}
                %{
            case 'optimized'
                % This might not be preferable given the performance cost
                [bkgdTrDeltaSDO, bkgdTrJointSDO] = SAT.compute.sdo7(pxt0_Bkgd(:,rand_idx), pxt1_Bkgd(:,rand_idx), 0, ...
                    "parallelCompute",vars.parallelCompute, rescale=false); 
                %}
        end
        %// iteratively update
        nTotalTrLength  = nTotalTrLength + bkgndLen; 
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

        tmp = cell(1, N_TRIALS); 

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
            switch vars.method
                case {'original', 'optimized'} %'original'
                    [trShuffDeltaSDO, trShuffJointSDO] = SAT.compute.sdo3(px0ShuffSS, px1ShuffSS, 0, ...
                        "parallelCompute",vars.parallelCompute, rescale=false); 
                case 'asymmetric'
                    [trShuffDeltaSDO, trShuffJointSDO] = SAT.compute.sdo5(px0ShuffSS, px1ShuffSS, 0, ...
                        'asymmetry', asymmetry_type, ... 
                        "parallelCompute",vars.parallelCompute, rescale=false);
                    %{
                case 'optimized'
                    [trShuffDeltaSDO, trShuffJointSDO] = SAT.compute.sdo7(px0ShuffSS, px1ShuffSS, 0, ...
                        "parallelCompute",vars.parallelCompute, rescale=false);               
                    %}
            end

            % __ 
            %// We are averaging the transitions from each time bin in the
            %pre-spike to each time bin in the post-spike, then averaging
            %over all spikes. Hence, the average effects may be derived
            %from the distributions of state
            %
            switch vars.method
                case 'original'
                    [trDeltaSDO, trJointSDO] = SAT.compute.sdo3(obsPxt0Cell{1,tr}{m,u},obsPxt1Cell{1,tr}{m,u}, 0, ...
                        parallelCompute=vars.parallelCompute, rescale=false); 
                case 'asymmetric'
                    [trDeltaSDO, trJointSDO] = SAT.compute.sdo5(obsPxt0Cell{1,tr}{m,u},obsPxt1Cell{1,tr}{m,u}, 0, ...
                        'asymmetry', asymmetry_type, ... 
                        parallelCompute=vars.parallelCompute, rescale=false);
                case 'optimized'
                    [trDeltaSDO, trJointSDO] = SAT.compute.sdo7(obsPxt0Cell{1,tr}{m,u},obsPxt1Cell{1,tr}{m,u}, 0, ...
                        parallelCompute=vars.parallelCompute, rescale=false); 
            end           
            tmp{tr} = trDeltaSDO;
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
        if vars.condenseShuffles
            disp("... Iteratively bootstrapping to condense shuffles..."); 

            %// Necessary for large numbers of shuffles/State; 
            % take original calculation of statistics (for compatibility)
            % Try to reduce statistics to something which can be estimated
            % using parametric stats; 
            % __ Need to feed in data; here
            sdo(m).bkgrndJointSDO   = bkgdJointSDO; 
            sdo(m).bkgrndSDO        = bkgdDeltaSDO; 
            %__
            sdo = SAT.compute.performStats(sdo, m,u); 
            %
            boot_shuff_mn = bootstrapz(sdo(m).shuffles{u}.SDOShuff, ...
                @mean, 1000, 'passNormal', 1, "iterative",1); 
            boot_shuff_std = bootstrapz(sdo(m).shuffles{u}.SDOShuff, ...
                @std, 1000, 'passNormal', 1, "iterative", 1); 
            boot_joint_mn = bootstrapz(sdo(m).shuffles{u}.SDOJointShuff, ...
                @mean, 1000, 'passNormal', 1, 'iterative',1); 
            boot_joint_std = bootstrapz(sdo(m).shuffles{u}.SDOJointShuff, ...
                @std, 1000, 'passNormal', 1, 'iterative', 1); 
            %// Need to take the mean and std independently to avoid
            %narrowing the variance of the simulated distributions; 
            sdo(m).shuffles{u}.SDOShuff_mean        = median(boot_shuff_mn, 3); 
            sdo(m).shuffles{u}.SDOShuff_std         = median(boot_shuff_std,3); 
            sdo(m).shuffles{u}.SDOJointShuff_mean   = median(boot_joint_mn, 3); 
            sdo(m).shuffles{u}.SDOJointShuff_std    = median(boot_joint_std,3); 
            % ___ Remove (to save memory)

            if retainShuffles == 0
                % // temporary toggle off; 
                sdo(m).shuffles{u}.SDOShuff = []; 
                sdo(m).shuffles{u}.SDOJointShuff = [];
            end
        else
            %// Take the elements from the distributions directly; 
            sdo(m).shuffles{u}.SDOShuff_mean        = mean(sdo(m).shuffles{u}.SDOShuff,3); 
            sdo(m).shuffles{u}.SDOShuff_std         = std( sdo(m).shuffles{u}.SDOShuff, 1, 3); 
            sdo(m).shuffles{u}.SDOJointShuff_mean   = mean(sdo(m).shuffles{u}.SDOJointShuff,3); 
            sdo(m).shuffles{u}.SDOJointShuff_std    = std( sdo(m).shuffles{u}.SDOJointShuff,1,3); 

        end
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