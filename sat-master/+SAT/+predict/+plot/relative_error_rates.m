%% predictSDO_plot_relative_error_rates
% Variant of the plotter to compare the accumulation of E1/E2/E3 errors of two
% specified hypotheses.  
%
% May be useful for comparing the STA and SDO or SDO to background; 
%
% Because yyaxis elements are not handled well in inkscape, if saving plots
% as SVGs, save the left and right axes separately. 
%
% INPUTS: 
%   - errorStruct:  Standard error structure 
%   - compCell: A {Mx2} cell containing strings/char matching the hypothesis 
%       names used in errorStruct; Each row (M) is a tested combination to
%       plot. 
%   OPTIONAL NAME-VALUE PAIRS: 
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

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

function relative_error_rates(errorStruct, compCell, varargin)
%%
p = inputParser; 
addOptional(p, 'saveFig', 0); 
addOptional(p, 'saveFormat', 'png');
addOptional(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG        = pR.saveFig; 
SAVE_FMT        = pR.saveFormat; 
SAVE_DIR        = pR.outputDirectory; 
N_COMP          = size(compCell,1); 

[x0, XI]        = sort(errorStruct(1).x0States); 
N_SPIKES        = length(x0); 
SIMPLE_PLOT     = SAVE_FIG && strcmp(SAVE_FMT, 'svg'); 
MAX_OBS_STATE   = max(x0); 

%%

sfields = {errorStruct.fieldname}; 

efields = {'L0_running', 'L1_running', 'L2_running'}; 
etitles = {'L0', 'L1', 'L2'}; 

f = figure; 
for ee = 1:3
    nn = strcat('f',num2str(ee)); 
    subplot(1,3,ee); 
    hold on; 
    lgnd = cell(N_COMP,1); 
    for r = 1:N_COMP
        fName1 = compCell{r,1}; 
        fName2 = compCell{r,2};
        x1_ix = strcmp(fName1, sfields); 
        x2_ix = strcmp(fName2, sfields); 
        %
        x1 = cumsum(errorStruct(x1_ix).(efields{ee})(XI)); 
        x2 = cumsum(errorStruct(x2_ix).(efields{ee})(XI)); 
        %
        plot(x1-x2); 
        lgnd{r} = strcat(fName1, "-", fName2); 
    end
    if ~SIMPLE_PLOT
        %// plot yyaxis 
        yyaxis right
        plot(1:N_SPIKES, x0, 'color', [0,0.804,0.4]); 
        ylabel("T_0 State of sorted Spike")
        axis([0,N_SPIKES, 1, MAX_OBS_STATE]);
        ax = gca;
        ax.YColor = [0,0.804,0.4]; % green/olive
        %-- 
        yyaxis left    
        %-- 
        legend(lgnd, 'location', 'northwest');
        title( strcat("Cumulative \Delta", etitles{ee}, " error") ); 
        axis([1,N_SPIKES,-inf,inf]);
        hold off
    end
end

if SIMPLE_PLOT
    %// plot yyaxes on different fig; 
    f2 = figure; 
    for n = 1:3
        subplot(1,3,n); 
        plot (1:N_SPIKES, x0, 'color', [0,0.804,0.4])
        ylabel("T_0 State of sorted Spike")
        axis([0,N_SPIKES, 1, MAX_OBS_STATE]);
        ax = gca;
        ax.YColor = [0,0.804,0.4]; % green/olive      
    end
end

    
%% Save Module
if SAVE_FIG
    switch SAVE_FMT
        case 'png'
            plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'Delta_CumulativeErrorRates');      
        case 'svg'
            plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'Delta_CumulativeErrorRates'); 
            plot_saveModule(f2, SAVE_DIR, SAVE_FMT, 'Delta_CumulativeErrorRates-YYOverlay-'); 
    end
end

end