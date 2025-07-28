% Written specifically to work w/ the Object classes

% Makes the 'SAT.predict.plotter.m' redundant

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

function plotErrorStruct(errorStruct, vars)
arguments
    errorStruct
    vars.fill       = 0; 
    vars.alpha      = 0.05; 
    vars.nShuffles  = 1000;
    %
    vars.saveDirectory = []; 
    vars.saveFig = 0; 
    vars.saveFormat {mustBeMember(vars.saveFormat, {'png', 'svg'})} = 'png'; 
    vars.statType = 'sum'; 
    vars.plotProperties = []; 
    vars.x1 = []; % Allows us to figure out what these should be; 
end
SIG_PVAL    = vars.alpha; 
SAVE_FIG    = vars.saveFig; 
SAVE_FMT    = vars.saveFormat; 
SAVE_DIR    = vars.saveDirectory; 
STAT_TYPE   = vars.statType; 
N_SHUFFLES  = vars.nShuffles; 
INCLUDE_STATS = 1; 

%// Build the plotter
sfields = {errorStruct(:).fieldname};

if isempty(vars.plotProperties)
    plotProp = SAT.predict.assignPlotterProperties(sfields);
else
    plotProp = vars.plotProperties; 
end

%__________________________________________________________________________

SAT.predict.plot.error_v_state(errorStruct, ...
    'saveFig',          SAVE_FIG,...
    'saveFormat',       SAVE_FMT,...
    'outputDirectory',  SAVE_DIR,...    
    'plotProp', plotProp); 

x0 = errorStruct(1).x0States; 

if isempty(vars.x1) 
    x1 = x0; %dummy - Not ideal 
else
    x1 = vars.x1; 
end


for f  = 1:length(sfields)
    prd_px.(sfields{f}) = errorStruct(f).predicted_px; 
end

SAT.predict.plot.px_v_x(prd_px, x1); 
%SAT.predict.plot.px_v_x(prd_px, x0);

%
SAT.predict.plot.error_rates(errorStruct, ...
    'saveFig',          SAVE_FIG,...
    'saveFormat',       SAVE_FMT,...
    'outputDirectory',  SAVE_DIR,...
    'plotProp', plotProp); 

%
compCell = {'SDO', 't0t1'; 'STA', 'SDO'}; 
SAT.predict.plot.relative_error_rates(...
    errorStruct, ...
    compCell, ...
    'saveFig',          SAVE_FIG,...
    'saveFormat',       SAVE_FMT,...
    'outputDirectory',  SAVE_DIR...    
    );

%
PXFIELD = 'KLD';
SAT.predict.plot.pxDistance(errorStruct,PXFIELD, ...
    N_SHUFFLES, ...
    'saveFig',          SAVE_FIG,...
    'saveFormat',       SAVE_FMT,...
    'outputDirectory',  SAVE_DIR,...    
    'plotProp', plotProp);
%

PXFIELD2 = 'logLikelihood'; 
SAT.predict.plot.pxDistance(errorStruct,PXFIELD2, ...
    N_SHUFFLES, ...
    'saveFig',          SAVE_FIG,...
    'saveFormat',       SAVE_FMT,...
    'outputDirectory',  SAVE_DIR,...    
    'plotProp', plotProp);
%
PXFIELD3 = 'DStat'; 
SAT.predict.plot.pxDistance(errorStruct,PXFIELD3, ...
    N_SHUFFLES, ...
    'saveFig',          SAVE_FIG,...
    'saveFormat',       SAVE_FMT,...
    'outputDirectory',  SAVE_DIR,...    
    'plotProp', plotProp);


if INCLUDE_STATS 
   eFields = {'L0_running', 'L1_running', 'KLD', 'logLikelihood', 'DStat'}; 
   N_E_FIELDS = length(eFields);
   for f = 1:N_E_FIELDS
       SAT.predict.testSig(errorStruct, ...
        'pVal',             SIG_PVAL, ... 
        'nShuffles',        N_SHUFFLES, ... 
        'dataField',        eFields{f}, ...
        'statType',         STAT_TYPE, ...  
        'plotProp',         plotProp, ... 
        'saveFig',          SAVE_FIG, ... 
        'saveFormat',       SAVE_FMT, ... 
        'outputDirectory',  SAVE_DIR); 
   end
end


%__________________________________________________________________________

end