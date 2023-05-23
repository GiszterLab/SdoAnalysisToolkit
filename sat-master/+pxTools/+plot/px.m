%% plot_px
%
% A simple plotter for visually inpecting distributions. 
% Given an arbitrary number of px values, plot these as overlapping
% distributions on the same figure
%
% INPUTS
%   - pxData: [N x K] doubles array, summing to ~1 across a dimension,
%       corresponding to a probability distribution. 
%   - OPTIONAL NAME-VALUE PAIRS
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position        
%       'colors' - a cell array containing  [N x 3] RGB array, with values
%           scaled between 0-1. Number of triplets defined should match number
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

function plot_px(pxData, varargin)
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
%
addParameter(p, 'colors', 0); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

DEFINED_COLORS = 0; 
if ~isnumeric(pR.colors)
    DEFINED_COLORS = 1; 
    colorMap = pR.colors{1}; 
end
 
N_POLY = 1; 
N_BINS = length(pxData); 

[sz_y, sz_x] = size(pxData); 
if (sz_y > 1) || (sz_x > 1)
    ySum = sum(pxData,1); 
    xSum = sum(pxData,2); 
    % -- avg. sse
    xSumErr = sum((xSum-1).^2/sz_x); 
    ySumErr = sum((ySum-1).^2/sz_y); 
    % -- Comp dim
    if xSumErr < ySumErr
        N_POLY = sz_y;
        N_BINS = sz_x; 
        
        pxData = pxData'; 
    else
        N_POLY = sz_x; 
        N_BINS = sz_y; 
    end
end
    
%% PLOT

figure; 
hold on; 

xComp = [1:N_BINS N_BINS:-1:1]; 

for pl = 1:N_POLY
    yComp = [pxData(:,pl); zeros(N_BINS,1)]'; 
    pgon = polyshape(xComp, yComp, 'Simplify', false); 
    if DEFINED_COLORS
        plot(pgon, 'faceColor', colorMap(pl,:));
    else
        plot(pgon); 
    end
end
hold off    

gca;
xlim([0 N_BINS]); 
ylim([0 max(max(pxData))]); 
ylabel("P(state)");
xlabel("State");
title("P(x) by Condition"); 

%title("Spike-triggered change in State"); 
nameArr = cell(1,N_POLY); 
for pl = 1:N_POLY
    nameArr{pl} = ['Distribution' num2str(pl)]; 
end
legend(nameArr); 

%% Save module
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'Px', [0,0,800,400]); 
end


end