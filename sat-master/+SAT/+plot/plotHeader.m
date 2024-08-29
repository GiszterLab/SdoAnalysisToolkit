%% plotHeader
%
% Header script for the collection of plotter methods used to visualize
% the SDO and SDO effects, as called by the sdoMat and sdoMat classes
%
% All plotter subscripts may be called independently. 
% 
% PREREQUISITES:
%     sdoMat or sdoMultiMat
% INPUT PARAMETERS
%   sdo: 'sdoMat' or 'sdoMultiMat' Class
%   XT_SDO_CH_NO: Row index for the sdo structure, pointing to a particular
%       xtDataChannel
%   PP_SDO_CH_NO: Subindex for the sdo structure, pointing to a particular
%       ppDataChannel
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position
%       'normalize'      : [0/1] Whether to normalize the SDO w/ p(x0) prior to
%           plotting (i.e. the utilized effect vs. covariance-normed].
%               Default = 1; 
%       'colormap'       : ['sdo','parula','polar'] Colormaps for plotting.
%           default = 'sdo'; 

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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


% -->> This is the plot header for the OOP variant; 

function plotHeader(sdo, XT_SDO_CH_NO, PP_SDO_CH_NO, vars)
arguments
    sdo
    XT_SDO_CH_NO = 1; 
    PP_SDO_CH_NO = 1; 
    vars.filter = 1; 
    vars.saveFig = 0; 
    vars.saveFormat {mustBeMember(vars.saveFormat, {'png' ,'svg'})} = 'png'; 
    vars.outputDirectory = [];
    %vars.normalize = 1; 
end

%________
if vars.saveFig
    %// Avoid querying user for ALL modules, if not passed, but figs are
    %saved
    if isempty(vars.outputDirectory)
        % Get Directory Once, then Pass to All; 
        vars.outputDirectory = uigetdir([], "Choose Directory to save Figures to"); 
    end
end

%% METHODS

classType = class(sdo); 
switch classType
    case 'sdoMat'
        sdoStruct = sdo.bungleSdoStruct; 
    case 'sdoMultiMat'
        sdoStruct = sdo.sdoStruct; 
end

txtStr = strcat("Plotting ", sdoStruct(XT_SDO_CH_NO).signalType, " x ", sdoStruct(XT_SDO_CH_NO).neuronNames{PP_SDO_CH_NO}); 

disp(txtStr); 

%__ SDO Shape

% __ Covariance normalized; 
SAT.plot.plotJointDiffSDO(sdoStruct,XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'filter',           vars.filter, ...
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory, ...
    'normalization',        'px0'); 

% __ State normalized; 
SAT.plot.plotJointDiffSDO(sdoStruct,XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'filter',           vars.filter, ...
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory, ...
    'normalization',        'unity'); 


try
    SAT.plot.plotSplitSymmetrySDO(sdoStruct,XT_SDO_CH_NO, PP_SDO_CH_NO, ...
        'filter',           vars.filter, ...
        'saveFig',          vars.saveFig, ...
        'saveFormat',       vars.saveFormat, ...
        'outputDirectory',  vars.outputDirectory, ...
        'normalization',    'px0'); 
catch
    %null: User doesn't have MATLAB 2019>
    1; 

end

%__ SDO Significance
SAT.plot.risingFallingState(sdoStruct, XT_SDO_CH_NO, PP_SDO_CH_NO, ....
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory); 

%}

SAT.plot.arraySig(sdoStruct, XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory, ...
    'normalization', 'px0'); 
%

SAT.plot.px0Sig(sdoStruct, XT_SDO_CH_NO, PP_SDO_CH_NO, ...
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory); %, ...
%_

unitSDO = sdoStruct(XT_SDO_CH_NO).sdos{PP_SDO_CH_NO}; 


% __________ Non-normalized; 
SAT.plot.quiverSDO(unitSDO, ... 
    'filter',           vars.filter, ...
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory, ...
    'headPos',          'end'); 

SAT.plot.shearSDO(unitSDO, ...
    'filter',           vars.filter, ...
    'saveFig',          vars.saveFig, ...
    'saveFormat',       vars.saveFormat, ...
    'outputDirectory',  vars.outputDirectory);  

%____ Normed SDOS; 
%{
%normSDO = SAT.sdoUtils.normsdo(unitSDO, sdoStruct(XT_SDO_CH_NO).sdosJoint{PP_SDO_CH_NO}); 
SAT.plot.quiverSDO(normSDO, ... 
    'filter',           FILTER, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR, ...
    'headPos',          'end'); 

SAT.plot.shearSDO(normSDO, ...
    'filter',           FILTER, ...
    'saveFig',          SAVE_FIG, ...
    'saveFormat',       SAVE_FMT, ...
    'outputDirectory',  SAVE_DIR);  
%}

%}

end
