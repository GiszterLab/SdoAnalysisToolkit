%% (plot) ArraySig
%
% Plot the elementwise significance of the SDO relative to the shuffles. 
% Plot the CDF of the cumulative magnitude of responses relative to
% shuffles. For use within the SDO Analysis Toolkit.
% 
% PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%   sdo: 'sdo' structure
%   XT_SDO_CH_NO: Row index for the sdo structure, pointing to a particular
%       xtDataChannel
%   PP_SDO_CH_NO: Subindex for the sdo structure, pointing to a particular
%       ppDataChannel
%   zTransform: [0/1] (Positional)
%       If 1, z transform the array elements before plotting significance
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Copyright (C) 2018 Maryam Abolfath-Beygi
% Copyright (C) 2022 Trevor S. Smith
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

function arraySig(sdo, XT_CH_NO, PP_CH_NO, varargin)
p = inputParser; 
addOptional(p, 'zTransform', 0); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
Z_TRANSFORM = pR.zTransform; 

%________

SIG_PVAL    = sdo(XT_CH_NO).stats{PP_CH_NO}.pVal; 
N_BINS      = length(sdo(XT_CH_NO).bkgrndSDO); 

ppName0     = sdo(XT_CH_NO).neuronNames{PP_CH_NO}; 
ppName      = underscores2spaces(ppName0); 
xtName      = sdo(XT_CH_NO).signalType; 

stRng = 1:N_BINS; 

%_____
unitSDO         = sdo(XT_CH_NO).sdos{PP_CH_NO}; 
SDOShuff        = sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff; 
meanShuffSDO    = mean(SDOShuff,3); 

bonFerrpVal = SIG_PVAL/N_BINS; %we decided to use this only in 1D
%bonFerrpVal = SIG_PVAL/(N_BINS^2);
zScore = norminv(1-bonFerrpVal/2);

sdo_std = std(SDOShuff, 0, 3); 

Z_STD = zScore* sdo_std; 

greater = (sdo(XT_CH_NO).sdos{PP_CH_NO} > (meanShuffSDO + Z_STD) ); 
lesser =  (sdo(XT_CH_NO).sdos{PP_CH_NO} < (meanShuffSDO - Z_STD) ); 
sdoMat = greater-lesser; 
%________
figure; 
% 
subplot(1,2,1)

imagesc(stRng, stRng, sdoMat, [-1, 1] ); 
c = ([  102,179,255;    %// red
        255,255,255;    %// white
        255,102,102]);  %// blue
colormap(c/255); 
    
line( [0,N_BINS], [0,N_BINS], 'lineStyle', '--', 'lineWidth', 2, 'color', 'k'); 

axis xy

ax = gca;
ax.XTick = stRng;
ax.YTick = stRng;
set(ax,'XGrid','on','YGrid','on')
labels = string(ax.XTickLabels); % extract
labels(1:2:end) = nan; % remove every other one
ax.XTickLabels = labels; % set
ax.XTickLabelRotation = -90;
labels = string(ax.YTickLabels); % extract
labels(1:2:end) = nan; % remove every other one
ax.YTickLabels = labels; % set

xlabel('Current State')
ylabel('Next State')
title({'SDO vs Shuffled SDO'; strcat('pVal=', num2str(SIG_PVAL))}); 
ax = colorbar;
ax.Ticks = [-0.66 0 0.66];
%ax.TickLabels = {latex('SDO<\bar{x}'), 'non-sig', latex('SDO>\bar{x}')}; 
ax.TickLabels = {'SDO<shuff','non-sig.','SDO>shuff'};
pbaspect([1 1 1]); 

%_____
subplot(1,2,2)

%// 
if isempty(SDOShuff)
    SDOShuff = zeros(N_BINS, N_BINS, 1); 
end

[~,T, testStat]=sigSSquaredCalculator(SDOShuff, unitSDO, SIG_PVAL, Z_TRANSFORM); 

SAT.plot.getCommonCdfPlot(T, testStat, SIG_PVAL)

pbaspect([1,1,1]);         

if Z_TRANSFORM == 1
    suptitle2({strcat(ppName, " on ", xtName); ' (Z-Scored)'});  
else
    suptitle2(strcat(ppName, " on ", xtName)); 
end
    
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "2DArray_SDO_sig"); 
end
    

end