%% plot_sta_v_x()
%
% Used to evaluate the state-dependent STA; 
% Effectively, plot a A(t) signal by x(s);
% INPUT: 
%   at0 = Pre-spike Signal Amplitude  [N_X0PTS x N_OBS Array]
%   at1 = Post-spike Signal Amplitude [N_X1PTS x N_OBS Array]
%   xs  = State-at-spike              [1 x N_OBS] Vector
%       - If xs is not provided, STA will be calculated across all events. 
%   OPTIONAL NAME-VALUE PAIRS:
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position          
%       'binMs'         : Relationship between time interval and bin size.
%           (only used in setting proper x axes ticks). 
%       'colors' - a cell array containing  [N x 3] RGB array, with values
%       s   caled between 0-1. Number of triplets defined should match number
%           of distributions to draw. 

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

function sta_v_x(at0, at1, xs, varargin)
%
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
addParameter(p, 'newFig', 1); 
% -- 
addParameter(p, 'binMs', 0); 
addParameter(p, 'colors', 0); 

parse(p, varargin{:}); 
pR = p.Results; 

DEFINED_COLORS = 0; 
try pR.colors +1; 
catch
    DEFINED_COLORS = 1; 
    colorMap = pR.colors{1}; 
end

if pR.binMs > 0
    DEFINED_UNITS   = 1;
    TBIN_PERIOD     = pR.binMs; 
else
    DEFINED_UNITS   = 0; 
end

NEW_FIG     = pR.newFig; 
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

[N_A0_TBINS, N_SPIKES]  = size(at0);
N_A1_TBINS              = size(at1,1); 

N_TBINS = N_A0_TBINS+N_A1_TBINS;

if ~exist('xs', 'var')
   xs = []; 
end
if isempty(xs)
    %// default all spikes
    xs = ones(1, N_SPIKES); 
end

X_STATES = unique(xs); 
N_STATES = length(X_STATES); 
%%

if DEFINED_COLORS
    cArray = colorMap; 
else
    cArray = rgb_colorGen(N_STATES);
end
    
atArray = [at0; at1]; 
if NEW_FIG
    figure; 
end
hold on; 

maxY = 0; 
for xx = X_STATES
    xV = (X_STATES == xx); 
    xi = find(xs == xx); 
    nSpikes = length(xi); 
    if nSpikes < 1
        continue; 
    end
    xVals   = atArray(:,xi)';
    if nSpikes > 1
        xSta    = mean(xVals,1); 
        xStd    = std(xVals,1); 
        py      = polyshape( ...
            [1:N_TBINS N_TBINS:-1:1], ...
            [xSta+xStd fliplr(xSta-xStd)],...
            'simplify', false); 
        f(xx) = plot(py, 'FaceColor', cArray(xV,:), 'FaceAlpha', 0.2);  
        j(xx) = plot(xSta, 'color', cArray(xV,:), 'LineWidth', 2); 
        maxY = max(maxY, max(xSta+xStd)); 
    else
        xSta    = xVals;
        f(xx) = plot(xSta, 'color', cArray(xV,:), 'LineWidth', 2); 
        maxY = max(maxY, max(xSta)); 
    end
end


maxY2 = maxY*1.1; 

if ~any([at0;at1]<0)
    try
        axis([1, N_TBINS, 1, maxY2]); 
    catch
        axis([1, N_TBINS, -inf, inf]); 
    end
else
    axis([1, N_TBINS, -inf, inf]); 
end
% Time elements at t=1;

if DEFINED_UNITS
    xtk1    = [ (0:1/TBIN_PERIOD:N_A0_TBINS-1/TBIN_PERIOD) ...
        (N_A0_TBINS:1/TBIN_PERIOD:N_A0_TBINS+N_A1_TBINS+1/TBIN_PERIOD) ]; 
    xtk1    = unique(xtk1); 
    xticks(xtk1); 
    xtLbls = (xtk1-N_A0_TBINS)*TBIN_PERIOD;
    set(gca, 'XTickLabel', xtLbls); 
    %
    xlabel("Time relative to Spike (ms)")    
else
    xtk1 = xticks; 
    xtLbls = (xtk1 - N_A0_TBINS); 
    set(gca, 'XTickLabel', xtLbls);
    %
    xlabel("Time Bins relative to Spike")        
end

xline(N_A0_TBINS+0.5, 'color', 'r'); 
%line( [N_A0_TBINS+0.5, N_A0_TBINS+0.5], [0, maxY2], 'color', 'r');
text(N_TBINS-2, 2, strcat("N=",num2str(N_SPIKES)), 'color', 'r'); 
if N_STATES > 1
    title("Signal STA, by State at Spike"); 
else
    title("Signal STA"); 
end

ylabel("Signal Amplitude"); 
title("STA\pm1 STD"); 
%// Bungle fig handles to properly label legends
if N_STATES > 1
    lgnd = cell(1,N_STATES); 
    for xx = 1:N_STATES
        lgnd{xx} = strcat('x|s =', num2str(X_STATES(xx))); 
    end
    legend(f(X_STATES), lgnd); 
end

%% Save Module

if SAVE_FIG
    f = gcf; 
    if N_STATES > 1
        plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'STA_v_Xs'); 
    else
        plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'STA'); 
    end
end

end