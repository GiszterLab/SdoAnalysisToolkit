%% (Predict Spike Plotter -- Plot) Error rate vs. State
%
% Plots the average prediction error by states, as calculated from the
% prespike components
%
% The errorStruct, 'Lx_x_state' components are the total cumulative error,
% normalized by the number of predictions from that state; effectively a
% mean. If we want to look at the 'mode' or 'median' error from a state, we
% need to recalculate from the 'running' error fields
%
% INPUTS: 
%   'errorStruct' - The datastructure containing data information for the
%       prediction. 
%   OPTIONAL NAME-VALUE PAIRS: 
%       - saveFig       - [0/1]; whether to trigger the save module
%       - saveFormat    - ['png'/'svg'] 
%       - outputDirectory- String containing path. If not provided, will
%           query user
%       - plotProp      - Structure containing the common plotter
%           properties for the hypotheses
%       - method        - 'mean', 'median', or 'mode'. Default 'mean'

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

function error_v_state(errorStruct, varargin)
%%
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
addParameter(p, 'plotProp',0); 
%
addParameter(p, 'method', 'mean'); %{'mean', 'median', 'mode'}
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
METHOD      = pR.method; 

%// toggle custom line properties for Hypotheses
if isstruct(pR.plotProp) 
    CUSTOM_PLOT = 1; 
    plotProp = pR.plotProp; 
else
    CUSTOM_PLOT = 0; 
    plotProp = []; 
end

[x0, xi]    = sort(errorStruct(1).x0States); 
N_BINS      = length(errorStruct(1).L0_x_state); 

sfields = {errorStruct.fieldname}; 
N_FIELDS = length(sfields); 

etitles = {'1/0  Error', 'Magnitude of Error', 'Squared Magnitude of Error'}; 

nx0 = histcounts(x0, 1:N_BINS+1);

x_obs = unique(x0); 

efields = {'L0_running', 'L1_running', 'L2_running'}; 

methStr = capitalizeLine(METHOD); 

figure; 
for ee = 1:3
    subplot(1,3,ee)
    dat = zeros(N_BINS, N_FIELDS); 
    %_________
    switch METHOD
        case {'mean', 'Mean'}
            efields = {'L0_x_state', 'L1_x_state', 'L2_x_state'}; 
            for hh = 1:N_FIELDS
                dat(:,hh) = (errorStruct(hh).(efields{ee}))./nx0; 
            end     
        case {'median', 'Median'}
            %// Hack-around
            for hh = 1:N_FIELDS
                for xx = x_obs
                    LI = xi(x0 == xx); %indexed position of states matching query
                    dat(xx,hh) = median( errorStruct(hh).(efields{ee})(LI) ); 
                end
            end
        case {'mode', 'Mode'}
            %// Hack-around
            for hh = 1:N_FIELDS
                for xx = x_obs
                    LI = xi(x0 == xx); %indexed position of states matching query
                    dat(xx,hh) = mode( errorStruct(hh).(efields{ee})(LI) ); 
                end
            end
    end
    %_________
    b = bar(dat, 'stacked', 'LineWidth', 0.001); 
    if CUSTOM_PLOT
        for hh=1:N_FIELDS
            b(hh).FaceColor = plotProp.(sfields{hh}).color; 
        end
    end    
    title (strcat(methStr, " ", etitles{ee}, " prediction error, by state")); 
    legend(sfields, 'location', 'northeast'); 
    xlabel('x_0 State'); 
    ylabel(strcat(methStr, " [", etitles{ee}, '|x_0]'));      
end
       
%% Save Module
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'Average_predictionError_x_state', [0,0,1920,1200]); 
end
end