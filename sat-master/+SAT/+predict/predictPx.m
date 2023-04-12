%% predictSDO_predictPx
% 
% Having generated the SDO, predict post-spike behavior using the same (or
% other) ppData and xtData data structures. The name of the
% xtDataChannel and ppDataChannel within xtData and ppData must
% match the names provided within sdo. 
%
% Gaussian Convolution uses same filter settings for drawing distributions
% of state, to a minimum standard deviation of 1 state. 
%
% NOTE: This is (currently) only for single neuron, 1-step prediction.
% Background is not subtracted from spike-triggered effects (because these
% would normally be added back in anyway to multi-neuron responses)
% 
% PREREQUISITES: 
%   computeSDO()
% INPUT: 
%   - sdo : standard sdo structure
%   - xtData : xtData structure, with matching ID fields to sdo
%         May be same structure used to generate sdo, or different
%   - ppData : ppData structure, with matching ID fields to sdo
%         May be same structure used to generate sdo, or different
%   - XT_DC_CH_NO: Integer. Row index for xtData
%   - PP_DC_CH_NO: Integer. Row index for ppData 
%   OPTIONAL NAME-VALUE PAIRS:
%   - 'xtID': [string/char] Channel identifier for xtData
%   - 'ppID': [string/char] Channel identifier for ppData
%   - 'xtIDField': [string/char] fieldname/ID for xtData, if not 'electrode'
%   - 'ppIDField': [string/char] fieldname/ID for ppData, if not 'electrode'
%   - 'xtDataField': [string/char] fieldname for timeseries signal in
%       xtData if not 'envelope'
%   - 'nDtIntervals': [numeric]: How many steps forward to predict
%       (relative to the size of points used in SDO)
%   - 'staType': {'avg_px', 'px_sta'}
%           - Whether to use the average post-spike distribution (avg_px) or
%           the state distribution of the sta impulse response (px_sta) as
%           the probabilistic definition of 'sta' 
%           - Default = 'avg_px'
%   - 'mkvDist': {'px0', 'px1'}
%           - Whether to use the prespike (px0) or postspike (px1)
%           distribution for estimating the 1-step markov matrix.
%           -Default = 'px0' 
%
% OUTPUT: 
%   predicted_px: Structure containing predicted distributions, by
%       hypothesis
%   observed_px: Structure containing the pre-spike and post-spike state
%       distributions
%   observed_at: Structure containing the pre-spike and post-spike raw
%       signal amplitudes. 
%   normTArr: Structure containing the normalized transition matrices


% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [predicted_px, observed_px, observed_at, normTArr] = predictPx(sdo, xtData, ppData, XT_DC_CH_NO, PP_DC_CH_NO, varargin)
if ~exist('XT_DC_CH_NO', 'var')
    XT_DC_CH_NO = []; 
end
if ~exist('PP_DC_CH_NO', 'var')
    PP_DC_CH_NO = []; 
end
   
normStaType     = 'avg_px'; 
expectStaType   = {'avg_px', 'px_sta'};
normMkvType     = 'px0';  
expectMkvType   = {'px0', 'px1'}; 

p = inputParser; 
addParameter(p, 'xtID', ""); 
addParameter(p, 'ppID', ""); 
addParameter(p, 'xtIDField', 'electrode');
addParameter(p, 'ppIDField', 'electrode');
addParameter(p, 'xtDataField', 'envelope'); 
addParameter(p, 'nDtIntervals', 1); 
addParameter(p, 'staType', normStaType, ...
    @(x) any(validatestring(x, expectStaType)) ); 
%// new parameter for selecting dist for markov
addParameter(p, 'mkvDist', normMkvType, ...
     @(x) any(validatestring(x, expectMkvType)) );  

parse(p, varargin{:}); 
pR = p.Results; 

XT_ID_FIELD     = pR.xtIDField; 
PP_ID_FIELD     = pR.ppIDField; 
XT_DATA_FIELD   = pR.xtDataField; 
N_DT_INTERVALS  = pR.nDtIntervals; %how many forward-projections to go
STA_TYPE        = pR.staType; 
MKV_DIST        = pR.mkvDist; 

%_________ Test this... 

%//  Ensure referenced rows in sdo match referenced dataCell channels

[XT_DC_CH_NO, XT_SDO_CH_NO] = SAT.sdoUtils.match_DC_and_SDO_fields(...
    xtData,...
   {sdo.signalType}, ... 
    XT_DC_CH_NO,...
    XT_ID_FIELD, pR.xtID); 

[PP_DC_CH_NO, PP_SDO_CH_NO] = SAT.sdoUtils.match_DC_and_SDO_fields(...
    ppData,...
    sdo(XT_SDO_CH_NO).neuronNames, ...
    PP_DC_CH_NO,...
    PP_ID_FIELD, pR.ppID); 

%-- RESTORE P(X) PARAMS
if isfield(sdo, 'params')
    spp = sdo(XT_SDO_CH_NO).params.px; 
    %
    PX0_DURA_MS = spp.px0DurationMs; 
    PX1_DURA_MS = spp.px1DurationMs; 
    PX_FSM_WID  = spp.smoothingFilterWidth; 
    PX_FSM_STD  = spp.smoothingFilterStd; 
    PX_NSHIFT   = spp.x1StartShift; 
    PX_ZDELAY   = spp.x0x1Delay; 
end

XT_HZ = xtData{1,1}(XT_DC_CH_NO).fs; 

%// Derived Params

N_PX0_PTS = round(PX0_DURA_MS*XT_HZ/1000); 
N_PX1_PTS = round(PX1_DURA_MS*XT_HZ/1000 * N_DT_INTERVALS); 

N_BINS = length(sdo(XT_SDO_CH_NO).levels)-1; 

N_TRIALS = size(xtData,2); 

%% Statemap observations

sigLevels = sdo(XT_SDO_CH_NO).levels; 
if ~isfield(xtData{1,1}(XT_DC_CH_NO), 'signalLevels') 
    for tr=1:N_TRIALS
        xtData{1,tr}(XT_DC_CH_NO).signalLevels = sigLevels; 
    end
end

[pxt0Cell, pxt1Cell, ~,~, at0Cell, at1Cell] = pxTools.getTrialwisePxt( ...
    xtData, ppData, ...
    1:N_TRIALS, ...
    XT_DC_CH_NO, ...
    PP_DC_CH_NO, ...
    'xtDataField', XT_DATA_FIELD,...
    'pxNPoints', [N_PX0_PTS, N_PX1_PTS], ...
    'pxFilter',  [PX_FSM_WID,PX_FSM_STD], ...
    'pxShift',   PX_NSHIFT, ...
    'pxDelay',   PX_ZDELAY);     
    
% __ Flatten Arrays to conform 
at0     = stripCellWrapping(at0Cell, XT_DC_CH_NO); 
at1     = stripCellWrapping(at1Cell, XT_DC_CH_NO); 
pxt0    = stripCellWrapping(pxt0Cell, XT_DC_CH_NO); 
pxt1    = stripCellWrapping(pxt1Cell, XT_DC_CH_NO); 

xt0 = discretize(at0, sigLevels); 
xt1 = discretize(at1, sigLevels); 

%% Grab Normalized SDOs; 

u_dSDO     = sdo(XT_SDO_CH_NO).sdos{PP_SDO_CH_NO}; 
u_jSDO    = sdo(XT_SDO_CH_NO).sdosJoint{PP_SDO_CH_NO};

bk_dSDO     = sdo(XT_SDO_CH_NO).bkgrndSDO; 
bk_jSDO    = sdo(XT_SDO_CH_NO).bkgrndJointSDO; 

%// The output of normSDO are transition matrices and change-of-transition
%matrices
NORM_METHOD = 'px0'; %// Not currently using other parameters for this one
[u_NdSDO, u_NjSDO]      = SAT.sdoUtils.normsdo(u_dSDO, u_jSDO, NORM_METHOD); 
[bk_NdSDO, bk_NjSDO]    = SAT.sdoUtils.normsdo(bk_dSDO, bk_jSDO, NORM_METHOD); 

u_cNdSDO = SAT.sdoUtils.conformsdo(u_NdSDO);
bk_cNdSDO= SAT.sdoUtils.conformsdo(bk_NdSDO); 


%% Grab Standardized Transition Matrices --> 

switch STA_TYPE
    case 'avg_px'
        %// average spike-triggered pxt
        staPx = sum(u_jSDO,2); 
    case 'px_sta'
        %// probability distribution of the STA
        avgAt = mean(at1,2); %average post-spike amp = STA
        avgXt = discretize(avgAt, sigLevels); %sig-state of average pxt = 
        staPx = histcounts(avgXt, 1:N_BINS+1, 'Normalization', 'probability')';
end

switch MKV_DIST
    case 'px0'
        mkv_1xt = pxTools.getMarkovFromXt(xt0, N_BINS, 'conform', 1); 
    case 'px1' 
        mkv_1xt = pxTools.getMarkovFromXt(xt1, N_BINS, 'conform', 1);
end

%// Get the 'shifted STA' matrix, describing a 'constant offset'
sshiftMat = SAT.sdoUtils.stashiftmat(u_jSDO, staPx); 

normTArr = struct(); 
if 1 == 0
%if N_DT_INTERVALS == 1 
    %// Predict to recovered Joint SDOs Distributions; 
    % -- Recall L+1 = M; 
    matType = 'M'; 
    % __ [H1 T0 = T1]
    normTArr.t0t1       = pxTools.getH0Array(N_BINS, 0,0, matType); 
    % __ [H2] Gaussian Diffusion
    %// use a minimum of 1 state for diffusion
    normTArr.gauss      = pxTools.getH0Array(N_BINS, max(1, PX_FSM_WID), max(1, PX_FSM_STD), matType);
    % __ [H3 STA]
    normTArr.STA        = staPx*ones(1,N_BINS);     
    % __ [H4 Background SDO]
    normTArr.bck        = bk_NjSDO; 
    % __ [H5 Markov]
    normTArr.mkv        = mkv_1xt^N_PX1_PTS; 
    % __ [H6 STA + Background SDO]
    normTArr.staBck     = bk_NjSDO*(sshiftMat); %convolve
    % __ [H7 SDO]
    normTArr.SDO        = u_NjSDO; 
    
else
    %// Predict against Delta-SDOs
    matType = 'L'; 
    % __ [H1 T0 = T1]
    normTArr.t0t1       = pxTools.getH0Array(N_BINS, 0,0, matType); 
    % __ [H2] Gaussian Diffusion
    %// use a minimum of 1 state for diffusion
    normTArr.gauss      = pxTools.getH0Array(N_BINS, max(1,PX_FSM_WID), max(1,PX_FSM_STD), matType);
    % __ [H3 STA]
    normTArr.STA        = staPx*ones(1,N_BINS);      
    % __ [H4 Background SDO]
    normTArr.bck        = bk_cNdSDO; 
    % __ [H5 Markov]      
    normTArr.mkv        = mkv_1xt^N_PX1_PTS - eye(N_BINS); 
    %__ [H6 STA+Background SDO]
    normTArr.staBck     = SAT.sdoUtils.conformsdo(bk_NjSDO*sshiftMat-eye(N_BINS)); 
    %__ [H7 SDO]
    normTArr.SDO        = u_cNdSDO; 
end
    
%% Common Prediction Method
sfields = fields(normTArr); 
nFields = length(sfields); 
for hh = 1:nFields
    predicted_px.(sfields{hh}) = pxTools.predictPxtfromPx0(normTArr.(sfields{hh}), pxt0, N_DT_INTERVALS); 
end
%______
observed_px = struct( ... 
    't0_actual', pxt0, ...
    't1_actual', pxt1); 
%______
observed_at = struct(...
    't0_actual', at0, ...
    't1_actual', at1); 

if nargout == 1
    observed_px = []; 
    observed_at = []; 
    normTArr    = []; 
elseif nargout == 2
    observed_at = []; 
    normTArr    = []; 
elseif nargout == 3
    normTArr    = []; 
end

end
%% HELPER SUBFUNCTIONS

function [arrayOut] = stripCellWrapping(arrayIn, ROW_NO)
array1      = cellhcat(arrayIn); 
arrayOut    = cellhcat(array1(ROW_NO, :)); 
end

