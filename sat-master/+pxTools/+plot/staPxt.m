%% plot_staPxt
% Common Plotter for the spike-triggered averaged probability(x,t)
%
% Essentially a heatmap of discrete state by discrete time bin around
% spike; useful for interpretting the SDO and predicting if there will be
% significant effects (Effectively an STA-Pxt)
%
% ASSUMPTIONS: 
% `1) x0 and x1 are N_POINTS*N_OBS vectors of observed STATES (discrete) in
% time bins
% 2) Spike time is the terminal bin of X0
% 3) number of columns of x0 and x1 are the same (equal numbers of
% pre-spike and post-spike occurences). 
%
% Parameters as to the shapes of the pre/post spike intervals will be left
% to the user upstream
%
% INPUTS: 
%   x0 - A column vector of pre-spike states by relative spike position. 
%       [N_X0_PTS x N_SPIKES]
%   x1 - A column vector of post-spike states by relative spike position.
%       [N_X1_PTS x N_SPIKES]
%   N_STATES = Maximal value of states. If not passed, will use the
%       max observed value. 
%   OPTIONAL NAME-VALUE PAIRS: 
%       BY_STATE :  [0/1] If 1, segregate distributions by state at spike.
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position   
%       'binMs'         : Relationship between time interval and bin size.
%           (only used in setting proper x axes ticks). 
%       'colorbar'      : [0/1]. If 1, show colorbar. 0, no colorbar. 

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

function plot_staPxt(x0, x1, N_STATES, varargin)
p = inputParser;
addOptional(p, 'BY_STATE', 0); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png'); 
addParameter(p, 'outputDirectory', []); 
%--
addParameter(p, 'binMs', 0); 
addParameter(p, 'colorbar', 1);

parse(p, varargin{:}); 
pR = p.Results; 

BY_STATE        = pR.BY_STATE; 
USE_COLORBAR    = pR.colorbar; 

if pR.binMs > 0
    DEFINED_UNITS = 1; 
    TBIN_PERIOD = pR.binMs; 
else
    DEFINED_UNITS = 0; 
end

SAVE_FIG = pR.saveFig; 
SAVE_FMT = pR.saveFormat; 
SAVE_DIR = pR.outputDirectory; 

%
if ~exist('N_STATES', 'var')
    % ... there has to be a better way
    N_STATES = max(max(max(x0)), max(max(x1)));
end

[N_X0_TBINS, N_OBS] = size(x0); 
N_X1_TBINS = size(x1,1);
N_X0X1_TBINS = N_X0_TBINS + N_X1_TBINS; 
%
x0x1 = [x0;x1]; 

if BY_STATE
    stapxt_xx = zeros(N_STATES, N_X0X1_TBINS, N_STATES); 
    %// can use histcounts w/ the discrete state var
    for xx = 1:N_STATES
        for ti = 1:N_X0X1_TBINS %time index bin
            si      = (x0(N_X0_TBINS,:) == xx); %state-index (for state at spike)
            nSi     = nnz(si);
            if nSi < 1
                continue; 
            end
            xVals   = x0x1(ti,si); 
            pxi     = histcounts(xVals, 1:N_STATES+1)/nSi; 
            stapxt_xx(:,ti,xx) = pxi; 
        end
    end
    xxSum   = squeeze(sum(sum(stapxt_xx,1),2)); %vector of 
    zIdx    = xxSum> 0; 
    zVals   = find(zIdx); 
    % __ count x(s) for later reporting
    hc      = histcounts(x0(N_X0_TBINS,:), 1:N_STATES+1); 
    hcS     =  hc(zIdx); 
    stapxt = stapxt_xx(:,:,zIdx);
    
else
    stapxt = zeros(N_STATES, N_X0X1_TBINS); 
    for ti = 1:N_X0X1_TBINS %time index
        xVals   = x0x1(ti,:); 
        %// state probability at time index
        pxi     = histcounts(xVals, 1:N_STATES+1)/N_OBS;
        stapxt(:,ti) = pxi; 
    end
end

%%
Z_HEIGHT = size(stapxt,3); 

figure;

nCols = ceil(sqrt(Z_HEIGHT)); 
nRows = ceil(Z_HEIGHT/nCols); 

for zz = 1:Z_HEIGHT
    subName = strcat('f', num2str(zz));
    f.(subName) = subplot(nCols, nRows, zz); 
    %______
    imagesc(stapxt(:,:,zz)); 
    %// conform plot
    axis([1, N_X0X1_TBINS, 1, N_STATES]); 
    axis xy
    line([N_X0_TBINS+0.5, N_X0_TBINS+0.5], [1,N_STATES], 'Color', 'r'); 
    if DEFINED_UNITS
        %// set axes + ticks to whole numbers;
        x0Intrvl    = N_X0_TBINS*TBIN_PERIOD; 
        x1Intrvl    = N_X1_TBINS*TBIN_PERIOD; 
        x0_xticks0   = (1:x0Intrvl)/TBIN_PERIOD;
        x0_xticks   = [x0_xticks0 N_X0_TBINS]; %ensure spiketime is included;
        x0_xticks   = unique(x0_xticks); 
        x1_xticks   = (1:x1Intrvl)/TBIN_PERIOD+N_X0_TBINS; 
        xtks        = [x0_xticks x1_xticks]; 
        xtk_lbls    = (xtks-N_X0_TBINS)*TBIN_PERIOD;
        set(gca, 'XTick', xtks, 'XTickLabel', xtk_lbls)
        xticks(xtks);
        xlabel("Time relative to Spike (ms)")
    else
        %// Try to provide something which looks reasonable 
        xtks = xticks; 
        xticklabels(xtks - N_X0_TBINS); 
        xlabel("Time Bins relative to Spike")
    end
    ylabel("X(t)"); 
    if BY_STATE
        text(N_X0X1_TBINS-2.5, 2, strcat("N=", num2str(hcS(zz))), 'Color', [1,1,1]); 
        title(strcat("STA-P(x,t): x(s)=", num2str(zVals(zz)))); 
    else
        text(N_X0X1_TBINS-2.5, 2, strcat("N=", num2str(N_OBS)), 'Color', [1,1,1]); 
        title("STA-P(x,t)"); 
    end
    colormap bone
    
    if USE_COLORBAR
        colorbar; 
    end
end

%% Save module
if SAVE_FIG
    f = gcf; 
    if BY_STATE 
        plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'STA-Pxt_v_X', [0,0,1920,1080]); 
    else
        plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'STA-Pxt', [0,0,800,800]);
    end
end

end