%% predictSDO
%
% NOT RECOMMENDED (Preferred to use 'pxt' and 'sdoMat' classes to generate predictions).  
%
%  Standalone Header Script for predicting (and plotting) state from the SDO
% and a given dataset (xtDataCell + ppDataCell)
%
% 'sdo' should be loaded into memory, 'xtData' and 'ppData' should
% either be loaded into memory or defined; 

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

xtDataName  = 'emgCell';     
ppDataName  = 'spikeTimeCell'; 

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
SAVE_DIR        = ""; %targeted directory for saving figures; else will query.

%%
%______
if ~exist('xtData', 'var')
    xtData = eval(xtDataName); 
end
if ~exist('ppData', 'var')
    ppData = eval(ppDataName); 
end

%% Predict Post-spike Distributions

[predicted_px, observed_px, ~, normTMat] = SAT.predict.predictPx(...
    sdo, xtData, ppData,...
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
    plotProp = SAT.predict.assignPlotterProperties(sfields); 
    SAT.predict.plotter;
end

%% Varspace Cleanup
clear gg hh N_DT_INTERVALS nFields nFieldsObs ppDataName sfields sfieldsObs
clear STATE_ASSIGNMENT clear normTMat

