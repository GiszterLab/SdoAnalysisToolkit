%% (Predict-Spike Plotters: Plot) Error-Rates Stateordered
%
%Draw accumulating L0, L1, L2 prediction errors State-wise to evaluate
%trends. Post-spike states distributions are sorted by x0 State. 
%
% Because yyaxis elements are not handled well in inkscape, if saving plots
% as SVGs, save the left and right axes separately. 
%
% INPUTS: 
%   - errorStruct:  Standard error structure 
%   OPTIONAL NAME-VALUE PAIRS: 
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position
%       'plotProp'      : Specified struct containing the line-plotting
%           parameters for specified hypotheses

% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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

function error_rates(errorStruct, varargin)
%% Parse
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
addParameter(p, 'plotProp',0); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

%// toggle custom line properties for Prediction Hypotheses
if isstruct(pR.plotProp) 
    plotProp = pR.plotProp; 
else
    plotProp = []; 
end

[x0]            = sort(errorStruct(1).x0States); 
N_SPIKES        = length(x0); 
SIMPLE_PLOT     = SAVE_FIG && strcmp(SAVE_FMT, 'svg'); 

f = figure; 
%% Plot L0
subplot(1,3,1); 
getCumulativeErrorRateSubplot( errorStruct, "L0_running", SIMPLE_PLOT, plotProp);  
title("Cumulative L0 (0/1) error"); 

%% Plot L1
subplot(1,3,2); 
getCumulativeErrorRateSubplot(errorStruct, "L1_running", SIMPLE_PLOT, plotProp); 
title("Cumulative L1 error"); 

%% Plot L2
subplot(1,3,3); 
getCumulativeErrorRateSubplot(errorStruct, "L2_running", SIMPLE_PLOT, plotProp); 
title ("Cumulative L2 error"); 

%% Draw Right-side Overlays 
%// Separate figure for for SVGs
if SIMPLE_PLOT
    maxState = max(x0); 
    f2 = figure; 
    for n = 1:3
        subplot(1,3,n); 
        plot (1:N_SPIKES, x0, 'color', [0,0.804,0.4])
        ylabel("T_0 State of sorted Spike")
        axis([0,N_SPIKES, 1, maxState]);
        ax = gca;
        ax.YColor = [0,0.804,0.4]; % green/olive      
    end
end
    
%% SaveModule
if SAVE_FIG
    switch SAVE_FMT
        case 'png'
            plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'CumulativeErrorRates(T0_StateOrdered)', [0,0,1920,1080]); 
        case 'svg'
            plot_saveModule(f,  SAVE_DIR, SAVE_FMT, 'CumulativeErrorRates(T0_StateOrdered)', [0,0,1920,1080]); 
            plot_saveModule(f2, SAVE_DIR, SAVE_FMT, 'CumulativeErrorRates(T0_StateOrdered)-YYOverlay-', [0,0,1920,1080]); 
    end
end

end

function getCumulativeErrorRateSubplot( errorStruct, targetField, SIMPLE_PLOT, plotProp) 
%// restore Vars; 
fieldCells      = {errorStruct.fieldname}; 
[x0, XI]        = sort(errorStruct(1).x0States); 
N_FIELDS        = length(errorStruct);
N_SPIKES        = length(errorStruct(1).L0_running); 

if isstruct(plotProp)
    CUSTOM_PLOT = 1; 
else
    CUSTOM_PLOT = 0; 
end

hold on
if ~SIMPLE_PLOT
    yyaxis left
end

%-- Use specified Line plotting parameters, if supplied
for hh=1:N_FIELDS
    if CUSTOM_PLOT      
        fName   = fieldCells{hh}; 
        pC      = plotProp.(fName).color; 
        pLS     = plotProp.(fName).LineStyle; 
        pLW     = plotProp.(fName).LineWidth; 
        %// X0 state-ordered L0 Error
        plot(cumsum(errorStruct(hh).(targetField)(XI)), 'color', pC, 'Marker', 'none', 'LineStyle', pLS, 'LineWidth', pLW); 
    else
         plot(cumsum(errorStruct(hh).(targetField)(XI)), 'Marker', 'none'); 
    end
end

REF_FIELD = underscores2spaces(errorStruct(1).reference); 
xlabel(strcat("(",REF_FIELD, " State-ordered) Spiking Events")); 

%xlabel("(T_0 State-orded) Spiking Events")
ylabel("Cumulative Error")
ax = gca;
ax.YColor = [0, 0, 0]; % reset to black
%--
if ~SIMPLE_PLOT
    %// Skip if no YY axis
    yyaxis right
    plot (1:N_SPIKES, x0, 'color', [0,0.804,0.4])
    ylabel("T_0 State of sorted Spike")
    axis([0,N_SPIKES, 1, max(x0)]);
    ax = gca;
    ax.YColor = [0,0.804,0.4]; % green/olive
    %-- 
    yyaxis left
end
legend(fieldCells, 'location', 'northwest');  
hold off
end
