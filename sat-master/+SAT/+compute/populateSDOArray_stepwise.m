%% computeSDO_populateSDOArray (V2-Stepwise)
% Given supplied point-process and time series data sets, 
% compute the stochastic dynamic operator for every supplied combination. 
%
% Algorithm Version 2, which ensures linearity constraints are maintained
% in the resulting SDO matrix.
%
% (Depreciated) :: 'computeSDO_populateSDOArray.m' should be used
% preferentially, unless explicit elementwise differences are required. 
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
%       --> In the 'stepwise' algorithm, the number of pre-spike to
%       post-spike points must be identical. 
%
% OPTIONAL NAME-VALUE PAIRS: 
%   'fieldname': (character array)
%       - Field from xtDataCell containing time series data; 
%       - Default 'envelope'; 
%       - Default = 1; 
%   'nShuffles': [Integer]
%       - Number of reshuffles of spike ISIs to use for statistical control
%       on each neuron. 
%       - Default = 1000; 
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
function [sdo] = computeSDO_populateSDOArray_stepwise(xtData, ppData, pxNPoints, varargin)
p = inputParser; 
addParameter(p, 'xtIDField', 'electrode'); 
addParameter(p, 'ppIDField', 'electrode'); 
addParameter(p, 'fieldName', 'envelope');
addParameter(p, 'ppDataField', 'time'); 
addParameter(p, 'nShuffles', 1000);
addParameter(p, 'shuffMethod', 'ISI'); 
addParameter(p, 'verbose', 0); 
%__ CIF_Reshuffle-specific Parameters
addParameter(p, 'CIF_FIR', '-hg'); 
addParameter(p, 'CIF_TAU', 0.05); 

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

% // Precheck
if (N_PX0_PTS ~= N_PX1_PTS)
    disp("Warning! Cannot perform stepwise calculation of dP(x): Pre/Post spike intervals are not equal!"); 
    return
end
%}

%// Derivative Params
N_BINS          = length(xtData{1,1}(1).signalLevels) - 1; 
N_TRIALS        = size(xtData,2);
N_PP_CHANNELS   = length(ppData{1,1});  
N_XT_CHANNELS   = length(xtData{1,1}); 
XT_HZ           = xtData{1,1}(1).fs; 

%% PreCastArr
[sdo] = SAT.compute.sdoStruct_new(N_XT_CHANNELS); 
                
%%
spkANDshuffSpikeCell  = cell(N_PP_CHANNELS, N_TRIALS); 
spkANDshuffRasterCell = cell(N_PP_CHANNELS, N_TRIALS); 

for tr=1:N_TRIALS
    for u=1:N_PP_CHANNELS
        n_obs_tr_spikes = length(ppData{1,tr}(u).(PP_DATAFIELD)); 
        if n_obs_tr_spikes > 1
            spkTime = ppData{1,tr}(u).(PP_DATAFIELD); 
            switch SHUFF_METHOD 
                case{'ISI', 'isi'}
                    try
                        spkANDshuffSpikeCell{u,tr} = [spkTime; shuffleSpikesInsideRange(spkTime, spkTime(1), spkTime(end), N_SHUFF)]; 
                    catch
                        spkANDshuffSpikeCell{u,tr} = [spkTime';shuffleSpikesInsideRange(spkTime, spkTime(1), spkTime(end), N_SHUFF)]; 
                    end
                case {'CIF', 'cif'}
                    try
                        spkANDshuffSpikeCell{u,tr} = [spkTime; cifReshuffle(ppData{1,tr}(u).(PP_DATAFIELD), XT_HZ, N_SHUFF, CIF_TAU, 'method', CIF_FIR)];
                    catch
                        spkANDshuffSpikeCell{u,tr} = [spkTime'; cifReshuffle(ppData{1,tr}(u).(PP_DATAFIELD), XT_HZ, N_SHUFF, CIF_TAU, 'method', CIF_FIR)];
                    end
            end
        elseif n_obs_tr_spikes == 1
            firstSpikeTime = ppData{1,tr}(u).time(1); 
            spkANDshuffSpikeCell{u,tr} = repmat(firstSpikeTime, N_SHUFF+1, 1); 
        end
        spkANDshuffRasterCell{u,tr}= round(spkANDshuffSpikeCell{u,tr}* XT_HZ);
    end
end


%% New Algorithm
%// collect all observations of state/spike at once, then iterate over each
%shuffle, while maintaining linearity. 

trWiseTrLen         = zeros(1, N_TRIALS); 
stateMapCell_1xTr   = cell(1, N_TRIALS); 

for tr = 1:N_TRIALS
    stateMapCell_1xTr{tr}   = cell(N_XT_CHANNELS,1); 
    trWiseTrLen(tr)         = length(xtData{1,tr}(1).(SFIELD)); 
    for m = 1:N_XT_CHANNELS
        At = xtData{1,tr}(m).(SFIELD); 
        sigLevels = xtData{1,tr}(m).signalLevels;
        % // Ensure High/Low is conformed
        sLo = sigLevels(1); 
        sHi = sigLevels(end); 
        At(At<sLo) = sLo; 
        At(At>sHi) = sHi; 
        %
        xt = discretize(At, sigLevels); 
        stateMapCell_1xTr{1,tr}{m} = xt; 
    end
end
stateMapCell = cellhcat(stateMapCell_1xTr); 

trUnitCount = zeros(N_PP_CHANNELS, N_TRIALS); 
for u = 1:N_PP_CHANNELS
    trUnitCount(u,:) = cellfun(@size, spkANDshuffRasterCell(u,:), repelem({2}, 1, N_TRIALS));  
end

nTotalSpikes = sum(trUnitCount,2); 

LEdges = cumsum([zeros(N_PP_CHANNELS,1), trUnitCount(:,1:end-1)],2)+1; %Leading/Left Edges

%
trSpkANDShuff       = cellhcat(spkANDshuffRasterCell); 
trFSpkANDShuff      = trSpkANDShuff; 
trX0SpkANDShuff     = cell(N_PP_CHANNELS, 1); 
trX1SpkANDShuff     = cell(N_PP_CHANNELS, 1); 

%% GENERATE SPIKE + SHUFFLED INDICES

%// Make a gradient vector for prespike and postspike 
gVP0 = -N_PX0_PTS+1:0; 
gVP1 = 1:N_PX1_PTS; 
ga_x0_shuff = ones(N_SHUFF+1,1)*gVP0; 
% TODO: Go back and add a modify these to include delay values
ga_x1_shuff = ones(N_SHUFF+1,1)*gVP1; 

for u = 1:N_PP_CHANNELS
    zArr = zeros(size(trSpkANDShuff{u})); 
    for tr = 1:N_TRIALS
       t0 = LEdges(u,tr); 
       zArr(:,t0:end) = sum(trWiseTrLen(1:tr-1)); 
    end
    trFSpkANDShuff{u} = trFSpkANDShuff{u}+zArr;
    %// Positional unit gradient pre/post Spike
    u_ga_x0 = kron(ones(1, nTotalSpikes(u)), ga_x0_shuff); 
    u_ga_x1 = kron(ones(1, nTotalSpikes(u)), ga_x1_shuff);   
    %// Quickly replicate positional index arrays to 3D 
    pos_x0  = kron(trFSpkANDShuff{u}, ones(1,N_PX0_PTS));
    pos_x1  = kron(trFSpkANDShuff{u}, ones(1,N_PX1_PTS));     
    %// Sum gradient + positional indices ==> prespike/postspike indices
    x0_ix = pos_x0 + u_ga_x0; 
    x1_ix = pos_x1 + u_ga_x1;     
    %
    trX0SpkANDShuff{u} = x0_ix; 
    trX1SpkANDShuff{u} = x1_ix;    
end

%%
% --> Evaluate state values in prespike/postspike dt apart to calculate the
% markovs; 

xtLkup  = cellhcat(stateMapCell); 
LIE     = logical(repmat(eye(N_BINS), 1,1, N_SHUFF+1)); %3D logical index
NBINS_X_NSHUFF = N_BINS * (N_SHUFF+1); 

for m = 1:N_XT_CHANNELS
    tic;  
    for u = 1:N_PP_CHANNELS
        % ___ Calc over SPIKE+SHUFFLES
        jSDO = zeros(N_BINS, N_BINS, N_SHUFF+1); 
        % -- Measure x0 --> x1
        x0Arr = xtLkup{m}(trX0SpkANDShuff{u}); 
        x1Arr = xtLkup{m}(trX1SpkANDShuff{u}); 
        dxArr = x1Arr -x0Arr; 
        %// Find Unique Number of transitions
        %________________________
        UdXArr = unique(dxArr); 
        nUniq = length(UdXArr); 
        %// for each x0 state; iterate over number of unique transitions 
        for xx = 1:N_BINS
            for dx = 1:nUniq
                dxi = UdXArr(dx);     
                if (dxi + xx < 1) || (dxi+xx > N_BINS)
                    continue
                end
                jSDO(dxi+xx, xx,:) = sum( (x0Arr == xx) & (dxArr == dxi) ,2); 
            end
        end 
        
        %_________________________
        jSDO        = jSDO/(nTotalSpikes(u)*N_PX0_PTS); 
        ssD         = sum(jSDO,1); 
        dSDO        = jSDO; 
        dSDO(LIE)   = dSDO(LIE)-reshape(ssD,NBINS_X_NSHUFF,1); 
        % //Write-out  
        sdo(m).sdos{u}                  = dSDO(:,:,1); 
        sdo(m).sdosJoint{u}             = jSDO(:,:,1);  
        sdo(m).shuffles{u}.SDOShuff     = dSDO(:,:,2:end); 
        sdo(m).shuffles{u}.SDOJointShuff= jSDO(:,:,2:end);  
    end
    
    %// For background, use ALL points, calcuate Markov between x==> x+dt; 
    % --> when averaged, this is equivalent to above; 
    bkDt = [xtLkup{m}(1:end-N_PX0_PTS); xtLkup{m}(N_PX0_PTS+1:end)]; 
    nObs = size(bkDt,2); 
    bkMkv = pxTools.getMarkovFromXt(bkDt, N_BINS, ...
        'Normalization', 'none', 'conform' ,0); 
    bkDMkv = bkMkv - diag(sum(bkMkv,2)); 
    sdo(m).bkgrndJointSDO   = bkMkv/nObs; 
    sdo(m).bkgrndSDO        = bkDMkv/nObs; 
    
    % __ Final Writeout Metadata
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
    % _____
    
    toc; 
    if VERBOSE == 1
        disp(strcat("Finished Ch#",  num2str(m), "/", num2str(N_XT_CHANNELS))); 
    end
end

end