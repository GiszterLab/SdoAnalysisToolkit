
%% Draw Px0 Px1 Parameters
%
% Plotter for visualizing the relationships between pre-spike and post-spike
% distributions using the parameters found in the SDO Analysis Toolkit. 
%
% For use with visualizing the relationships between prespike and
% post-spike signal. 
%
% Variables: 
%   'newFig' [0/1] - Whether to produce a new figure or populate existing
%   'px0DuraMs' - Duration of pre-spike interval (ms)
%   'px1DuraMs' - Duration of post-spike interval (ms)
%   'zDelay'    - Delay between the end of prespike and start of post-spike
%               --> Delay of post-spike effect. 
%   'nShift'    - Translation of both time intervals (delay)
%               --> Delay of spike/ response
%   'fs'        - Sample Frequency- Default = 1000; 
% Output: 
%   f           - figure handle for the plot. 

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

function f = plotPx0Px1IntervalGraph(vars)
arguments
    vars.newFig = 1; % Open in a new figure; 
    vars.px0DuraMs = -10; 
    vars.px1DuraMs = 10; 
    vars.zDelay = 1; 
    vars.nShift = 0; 
    vars.fs = 1000; 
end


pts2ms = 1000/vars.fs; % number of points per milisecond; 

NSHIFT = vars.nShift*pts2ms; 
zDELAY = vars.zDelay*pts2ms; 

if vars.newFig
    f = figure(); 
end

px0_t1 = NSHIFT; 
px0_t0 = px0_t1+vars.px0DuraMs; 

px1_t0 = zDELAY-1 + NSHIFT; 
px1_t1 = px1_t0+vars.px1DuraMs-1; 

%____
%// Calculate Differentials //
px0_dt = px0_t1- px0_t0; 
px1_dt = px1_t1 -px1_t0; 
%___

tmin = min([0, px0_t0 - px0_dt]); 
tmax = max([0, px1_t1 + px1_dt]); 

% px0; 
r0 = rectangle('Position', [px0_t0, 0, px0_dt, 1]); 
r0.FaceColor = [0.839, 0.965, 1]; % Baby-Blue
text(px0_t0+px0_dt/2, 0.5, 'p(x_0)'); 

% px1
r1 = rectangle('Position', [px1_t0, 0, px1_dt, 1]); 
r1.FaceColor = [1, 0.878, 0.8]; % Dreamsicle
text(px1_t0+px1_dt/2, 0.5, 'p(x_1)'); 

% Spiketime
line([0,0], [0,1.25], 'LineWidth',2, 'Color', 'r', 'LineStyle','--'); 
hold on; 
scatter(0, 1.25, 50, 'red', "v", "filled"); 
text(0, 1.3, 1, "Spike (s)"); 


xlabel ('\Deltat Relative to Spike (ms)'); 

axis([tmin, tmax, 0, 1.4]); 


end