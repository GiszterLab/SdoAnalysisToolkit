%% Get Prediction Matrices 
% Segregated function for calling and evaluating the different predictions;
%
% Used as a single common method to call and create these elements; 
% 

function H_Struct = getPredictionMatrices(sdo, xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
arguments
    sdo % either sdoStruct, sdoMat, sdoMultiMat
    xtdc xtDataCell
    ppdc ppDataCell
    XT_CH_NO = 1; 
    PP_CH_NO = 1; 
    vars.type {mustBeMember(vars.type, {'M', 'L'})} = 'L'; 
    vars.staMethod {mustBeMember(vars.staMethod, {'dpx', 'px'})} = 'px'; 
end

sField = {'t0t1', 'gauss', 'STA', 'bck', 'mkv', 'staBck', 'SDO'};
for h = 1:length(sField) 
    H_Struct.(sField{h}) = {}; 
end
 %H_Struct = cell2struct(cell(1, 7), sField); 

% // First, figure out exactly -WHAT- 'sdo' is 
clID = class(sdo); 
switch clID
    case 'sdoMultiMat'
        %// preferable; 
        sdoStruct = sdo.sdoStruct; 
    case 'sdoMat'
        sdoStruct = sdo.bungleSdoStruct; 
    case 'struct'
        %// Assume this 'is' the struct 
        sdoStruct = sdo; 
end

nStates = length(sdoStruct(XT_CH_NO).sdos{PP_CH_NO}); 

SIG_HZ = xtdc.fs; 

filterStd = sdoStruct(XT_CH_NO).params.px.smoothingFilterStd;  

filterWid = sdoStruct(XT_CH_NO).params.px.smoothingFilterWidth; 
USE_TRIALS = 1:xtdc.nTrials; 

PX_NSHIFT = sdoStruct(XT_CH_NO).params.px.nShift; 
N_PX0_PTS = abs(round(sdoStruct(XT_CH_NO).params.px.px0DurationMs * SIG_HZ/1000));
N_PX1_PTS = round(sdoStruct(XT_CH_NO).params.px.px1DurationMs * SIG_HZ/1000);
PX_ZDELAY = sdoStruct(XT_CH_NO).params.px.zDelay; 

[obs_idx0, obs_idx1]    = ppdc.getPerieventIndices(...
    USE_TRIALS, PP_CH_NO, ...
    'fs', xtdc.fs, ...
    'n_shift',PX_NSHIFT, ...
    't0_nPoints', N_PX0_PTS, ...
    't1_nPoints',N_PX1_PTS, ...
    'z_delay', PX_ZDELAY); 

sigLevels = sdoStruct(XT_CH_NO).levels; 

at0 = xtdc.getValuesAtIndices(obs_idx0,...
    'useChannels', XT_CH_NO); 
at1 = xtdc.getValuesAtIndices(obs_idx1,...
    'useChannels', XT_CH_NO); 
%
at0 = at0{1}; 
at1 = at1{1}; 

xt0 = discretize(at0, sigLevels); 

%___ H1
H_Struct.(sField{1}) = SAT.predict.matrices.getH1(nStates, "type",vars.type); 

%__ H2

h2_fStd = max(1, filterStd); %Make sure to have at least SOME filter
h2_fWid = max(1, filterWid); %Make sure to have at least SOME filter

H_Struct.(sField{2}) = SAT.predict.matrices.getH2(nStates, ...
    "filterStd", h2_fStd, ...
    'filterWidth',h2_fWid, ...
    'type', vars.type); 

% __ H3 Spike-Triggered Average (STA)
%sta_method = 'effect'; 
%sta_method = 'px'; 


H_Struct.(sField{3}) = SAT.predict.matrices.getH3(nStates, ...
    at0, at1, sigLevels, ...
    'type', vars.type, ...
    'method', vars.staMethod); 

% __ H4 Background
H_Struct.(sField{4}) = SAT.predict.matrices.getH4(sdoStruct, XT_CH_NO, ...
    'type', vars.type); 

% __ H5 Markov 
H_Struct.(sField{5}) = SAT.predict.matrices.getH5(nStates, xt0,  N_PX1_PTS, ...
    'type', vars.type); 

% __ H6 STA + Background
H_Struct.(sField{6}) = SAT.predict.matrices.getH6(at0, at1, sdoStruct, XT_CH_NO, ...
    'type', vars.type, 'method',vars.staMethod); 

% __ H7
H_Struct.(sField{7}) = SAT.predict.matrices.getH7(sdoStruct,XT_CH_NO, PP_CH_NO, ...
    'type', vars.type); 

end