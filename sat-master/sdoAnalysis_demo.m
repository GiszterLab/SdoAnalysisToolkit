%% sdoAnalysis_demo
%
% Demonstration of the SDO Analysis Toolkit;  
% run an SDO analysis in completion using default settings with direct 
% script calls. 

% The two provided examples below were used in the demonstration figures in
% [Redacted for double blind review], et al, 2023. 

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

if ~exist('xtData', 'var') || ~exist('ppData', 'var')
    [fpath_xt, fdir1] = uigetfile('*.mat', 'Open example xtData'); 
    [fpath_pp, fdir2] = uigetfile('*.mat', 'Open example ppData'); 

    ffile1 = fullfile(fdir1, fpath_xt); 
    ffile2 = fullfile(fdir2, fpath_pp); 

    xtData0 = load(ffile1); 
    ppData0 = load(ffile2); 
    xtfield = fields(xtData0); 
    ppfield = fields(ppData0); 
    xtData = xtData0.(xtfield{1}); 
    ppData = ppData0.(ppfield{1}); 
end

%% 
%_____ BUILD SDO ________

%

SAT.validateDataHolders(xtData, ppData, 1); 

% // Run SDO analysis w/ default parameters; 
SAT.computeSDO; 

%// These can be changed to any value; we selected these for the demo and
%documentation.

% __ Single Motor Unit x Synergist EMG
XT_DC_CH_NO = 8; 
PP_DC_CH_NO = 12; 
% __ Spinal Interneuron x EMG
%XT_DC_CH_NO = 6; 
%PP_DC_CH_NO = 4; 

%// Find the reference fields in the SDO. 
XT_SDO_CH_NO = XT_DC_CH_NO; 
PP_SDO_CH_NO = PP_DC_CH_NO; 

%// Uncomment if using dataCells with different indexed elements than in
%original dataset.
%[~, XT_SDO_CH_NO] = match_DC_and_SDO_fields(xtDataCell, {sdo(:).signalType}, XT_DC_CH_NO, 'electrode');
%[~, PP_SDO_CH_NO] = match_DC_and_SDO_fields(ppDataCell, sdo(1).neuronNames,  PP_DC_CH_NO, 'electrode'); ; 

%// Plot SDO 
SAT.plotSDO(sdo, XT_SDO_CH_NO, PP_SDO_CH_NO); 

%_____ PREDICT SDO _________
%// Use SDO to predict on data it was constructed against; 
%// Generate Predicted-State Distributions; 
[predicted_px, observed_px, observed_at] = SAT.predict.predictPx(sdo, ...
    xtData, ppData, XT_DC_CH_NO, PP_DC_CH_NO); 

%// Assign predictions of single state from distributions
predicted_x = pxTools.getXfromPx(predicted_px); 
observed_x  = pxTools.getXfromPx(observed_px); 

sfields = fields(predicted_px); 
plotProp = SAT.predict.assignPlotterProperties(sfields); 

%// Plot predictions
SAT.predict.plotter;

disp("COMPLETE!"); 

%% Cleanup Variable Space
clear fdir1 fdir2 ffile1 ffile2 fpath_pp fpath_xt
clear xtData0 ppDatal0 xtfield ppfield
clear XT_SDO_CH_NO PP_SDO_CH_NO