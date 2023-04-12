%% predictSDO
%
%  Standalone Header Script for predicting (and plotting) state from the SDO
% and a given dataset (xtDataCell + ppDataCell)
%
% 'sdo' should be loaded into memory, 'xtDataCell' and 'ppDataCell' should
% either be loaded into memory or defined; 

xtDataCellName  = 'emgCell';     
ppDataCellName  = 'spikeTimeCell'; 

%// Positions are within the relative DATACELL
XT_DC_CH_NO = 8; 
PP_DC_CH_NO = 12; 
%XT_DC_CH_NO = 6; 
%PP_DC_CH_NO = 4; 
XT_CH_NAME = ""; 
PP_CH_NAME = ""; %for string matching; 

STATE_ASSIGNMENT = 'max'; %['max'/'mean'/'median']; 
N_DT_INTERVALS = 1; %[numeric]

%___ Plotter Module Toggle
PLOT_ON         = 1; 
SAVE_FIG        = 1; 
SAVE_FMT        = 'svg'; %['png'/'svg']; 
SAVE_DIR        = "C:\Users\Frog\Desktop\2022_SDO_Paper_Figs\_MATLAB_svg\DFSF69-08182020-VExCh17-New\"; %targeted directory for saving figures; else will query.

%%
%______
if ~exist('xtDataCell', 'var')
    xtDataCell = eval(xtDataCellName); 
end
if ~exist('ppDataCell', 'var')
    ppDataCell = eval(ppDataCellName); 
end

%% Predict Post-spike Distributions

[predicted_px, observed_px, ~, normTMat] = predictSDO_predictPx(...
    sdo, xtDataCell, ppDataCell,...
    XT_DC_CH_NO,...
    PP_DC_CH_NO,...
    "xtID", XT_CH_NAME, ...
    "nDtIntervals", N_DT_INTERVALS ...
    );

%% Assign States to Predicted Distributions
sfields     = fields(predicted_px); 
nFields     = length(sfields);
predicted_x = struct; 
for hh = 1:nFields
    predicted_x.(sfields{hh}) = pxTools.getXfromPx(predicted_px.(sfields{hh}), STATE_ASSIGNMENT); 
end

%% Assign States to Observed Distributions

%// Observed States
sfieldsObs  = fields(observed_px);  
nFieldsObs  = length(sfieldsObs); 
observed_x  = struct; 
for gg = 1:nFieldsObs
    observed_x.(sfieldsObs{gg}) = pxTools.getXfromPx(observed_px.(sfieldsObs{gg}), STATE_ASSIGNMENT); 
end

%% Plot Predictions

if PLOT_ON
    plotProp = predictSDO_assignPlotterProperties(sfields); 
    predictSdo.plotter;
end

%% Varspace Cleanup
clear gg hh N_DT_INTERVALS nFields nFieldsObs ppDataCellName sfields sfieldsObs
clear STATE_ASSIGNMENT clear normTMat

