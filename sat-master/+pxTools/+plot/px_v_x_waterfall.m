%% plot_px_v_x_waterfall 
%
% Accessory plotter used to help visualize the mapping between an prespike
% and postspike distribution, using average p(x|x,s). Here, visualized as a
% ribbon plot/waterfall
%
% This function could be applied to observed or predicted distributions;
% all which is requried is p(x|(s-dt,s)], p[x|(s,s+dt)], and x(s)
%
% Note that the xs passed should match the positional order of input
% distributions (as it is effectively used as an index)
%
% INPUT: 
%   px0 - [N_BINS x N_OBS] array of prespike state distributions, by
%   observation. 
%   px1 - [N_BINS x N_OBS] array of postspike state distributions, by
%   observation. 
%   xs  - State of signal at spike, [1 x N_OBS]; 
%   OPTIONAL NAME-VALUE PAIRS: 
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position          

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

function plot_px_v_x_waterfall(px0, px1, xs, varargin)
%
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

N_BINS      = size(px0,1); 

%%

avgPx0xs = zeros(N_BINS,N_BINS+1); 
avgPx1xs = zeros(N_BINS,N_BINS+1); 
avgDPx01 = zeros(N_BINS,N_BINS+1); 

for xx = 1:N_BINS
    si = (xs == xx); %spike-triggered state index
    if nnz(si) < 1
        continue
    end
    %
    avgPx0xs(:,xx) = mean(px0(:,si),2); 
    avgPx1xs(:,xx) = mean(px1(:,si),2);
    avgDPx01(:,xx) = avgPx1xs(:,xx) - avgPx0xs(:,xx); 
end
% -- Obs-wide averages
avgPx0xs(:,end) = mean(px0,2); 
avgPx1xs(:,end) = mean(px1,2); 
avgDPx01(:,end) = mean(px1-px0,2); 

%__ Grayscale + Red
gscRed = vertcat(flipud(colormap(bone(N_BINS))), [1,0,0]); %use for setting proper colorscheme with vertcat sSTA in row 1

figure; 

subplot(1,3,1); 
ribbon(avgPx0xs); 
axis xy
axis ij
colormap(gscRed); 
axis([0.5 N_BINS+1.5 0.5 N_BINS+0.5 0 1])
view([-90,82.5])
xlabel ("\bf{x|s}");
ylabel ("P[x,(s-\Deltat,s)|x,s]");
zlabel ("\bf{P(x|s)}");
title("Pre-spike state distributions, by state")

subplot(1,3,2); 
ribbon(avgPx1xs); 
axis xy
axis ij
colormap(gscRed)
axis([0.5 N_BINS+1.5 0.5 N_BINS+0.5 0 1])
view([-90,82.5])
xlabel ("\bf{x|s}");
ylabel ("P[x,(s,s+\Deltat)|x,s]");
zlabel ("\bf{P(x|s)}");
title("Post-spike state distributions, by state")

subplot(1,3,3);
ribbon(avgDPx01); 
axis xy
axis ij
colormap(gscRed);
axis([0.5 N_BINS+1.5 0.5 N_BINS+0.5])
view([-90,82.5])
xlabel ("\bf{x|s}");
ylabel ("P[x,(s,s+\Deltat)|x,s]");
zlabel ("\bf{P(x|s)}");
title("Change in peri-spike state distributions, by state")

%% Save module
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'Px_v_x_Waterfall', [0,0,1920,1080]); 
end

end