%% plotSDO
%
% Command script for the collection of plotter methods used to visualize
% the SDO and SDO effects.
%
% All called plotSDO subscripts may be called independently. 
% 
% PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%   sdo: 'sdo' structure
%   XT_SDO_CH_NO: Row index for the sdo structure, pointing to a particular
%       xtDataChannel
%   PP_SDO_CH_NO: Subindex for the sdo structure, pointing to a particular
%       ppDataChannel
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

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


function plotSDO(sdo, XT_SDO_CH_NO, PP_SDO_CH_NO, varargin)
p = inputParser; 
addParameter(p, 'filter', 1); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

FILTER      = pR.filter; 
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
%________
if SAVE_FIG
    %// Avoid querying user for ALL modules, if not passed, but figs are
    %saved
    if isempty(SAVE_DIR)
        SAVE_DIR = uigetdir([], "Choose Directory to save Figures to"); 
    end
end


%
if ~exist('XT_SDO_CH_NO', 'var')
    XT_SDO_CH_NO = 0; 
end
if ~exist('XT_SDO_CH_NO', 'var')
    PP_SDO_CH_NO = 0; 
end
if XT_SDO_CH_NO == 0
    XT_SDO_CH_NO = 1; 
end
if PP_SDO_CH_NO == 0
    PP_SDO_CH_NO = 1; 
end

txtStr = strcat("Plotting ", sdo(XT_SDO_CH_NO).signalType, " x ", sdo(XT_SDO_CH_NO).neuronNames{PP_SDO_CH_NO}); 
disp (txtStr); 

%% METHODS

%__ SDO Shape
SAT.plot.plotDiffSDO(sdo,XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'filter',           FILTER, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR); 

SAT.plot.plotJointDiffSDO(sdo,XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'filter',           FILTER, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR); 

%__ SDO Significance
SAT.plot.risingFallingState(sdo, XT_SDO_CH_NO, PP_SDO_CH_NO, ....
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR); 

SAT.plot.arraySig(sdo, XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR); 

SAT.plot.px0Sig(sdo, XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR); 

%__
unitSDO = sdo(XT_SDO_CH_NO).sdos{PP_SDO_CH_NO}; 

SAT.plot.quiverSDO(unitSDO, ... 
    'filter',           FILTER, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR, ...
    'headPos',          'end'); 

SAT.plot.shearSDO(unitSDO, ...
    'filter',           FILTER, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR);  
end
