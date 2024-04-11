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

function arraySig(sdoStruct, XT_CH_NO, PP_CH_NO, varargin)

normNormType = {'px0'}; 
expectNormType  = {'none','px0', 'unity'}; 

p = inputParser; 
addOptional(p, 'zTransform', 0); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
addParameter(p, 'normalization', normNormType, ... 
    @(x) any(validatestring(x, expectNormType)) ); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
Z_TRANSFORM = pR.zTransform; 

%________

SIG_PVAL    = sdoStruct(XT_CH_NO).stats{PP_CH_NO}.pVal; 
N_BINS      = length(sdoStruct(XT_CH_NO).bkgrndSDO); 

ppName0     = sdoStruct(XT_CH_NO).neuronNames{PP_CH_NO}; 
ppName      = underscores2spaces(ppName0); 
xtName      = sdoStruct(XT_CH_NO).signalType; 

stRng = 1:N_BINS; 

%_____
dSDO    = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; 
jSDO    = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 

%__ compatability patching
%if isfield(sdoStruct(XT_CH_NO).shuffles{PP_CH_
if isfield(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}, 'SDOShuff_mean')
    %if ~isempty(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff_mean) 
    if isempty(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff) 
        %PARAMETRIC = 0; 
        PARAMETRIC = 1; 
    else
        %PARAMETRIC = 1; % Preferable
        PARAMETRIC = 0; 
    end
else
    PARAMETRIC = 0; 
end

%|| Warp Shuffled null distributions by expected priors
if PARAMETRIC
    meanShuffSDO    = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff_mean; 
    meanShuffJoint  = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff_mean; 
    shuff_std       = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff_std; 
    switch pR.normalization
        case 'px0'
            %//if REPARAMETERIZE
            meanShuffSDO = SAT.sdoUtils.reparameterizeSdo(meanShuffSDO, meanShuffJoint, jSDO); 
            meanShuffSTD = SAT.sdoUtils.reparameterizeSdo(shuff_std,    meanShuffJoint, jSDO); 
        case 'unity'
            meanShuffSDO = SAT.sdoUtils.normsdo(meanShuffSDO, meanShuffJoint); 
            meanShuffSTD = SAT.sdoUtils.normsdo(shuff_std, meanShuffJoint); 
        case 'none'
            meanShuffSTD = mean(shuff_std,3); 
    end
else
    SDOShuff        = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff; 
    SDOShuffJoint   = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff; 
    switch pR.normalization
        case 'px0'
            rShuff        = SAT.sdoUtils.reparameterizeSdo(SDOShuff, SDOShuffJoint, jSDO);
            meanShuffSDO  = mean(rShuff, 3); 
            meanShuffSTD  = std(rShuff, 0, 3); 
        case 'unity'
            meanShuffSDO = SAT.sdoUtils.normsdo(SDOShuff, SDOShuffJoint); 
            meanShuffSTD = std(meanShuffSDO,0,3); 
        case 'none'
            meanShuffSDO  = mean(SDOShuff,3); 
            meanShuffSTD  = std(SDOShuff, 0, 3); 
    end
end

%_________

bonFerrpVal = SIG_PVAL/N_BINS; %we decided to use this only in 1D
%bonFerrpVal = SIG_PVAL/(N_BINS^2);
zScore = norminv(1-bonFerrpVal/2); % number of STD away for 1/way test for sig; 

Z_STD = zScore* meanShuffSTD; % Number of STD to be significant; 

dxMat = (dSDO-meanShuffSDO); % Difference in t-Test; 

greater = (dxMat   > Z_STD ); 
lesser =  (dxMat < -Z_STD ); 
sdoMatrix = greater-lesser; 
%________
figure; 
% 
subplot(1,2,1)

imagesc(stRng, stRng, sdoMatrix, [-1, 1] ); 
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
%{
if isempty(SDOShuff)
    SDOShuff = zeros(N_BINS, N_BINS, 1); 
end
%}

if PARAMETRIC
    % Reshuffle Dynamics?
    % __>> This isn't the best... 
    S = repmat(meanShuffSTD, 1, 1, 1000);
    G = repmat(meanShuffSDO, 1, 1, 1000); 
    R = randn(N_BINS, N_BINS, 1000); 
    Sh = G+S.*R; 
    %
    [~,T, testStat]=sigSSquaredCalculator(Sh, dSDO, SIG_PVAL); 
else
    [~,T, testStat]=sigSSquaredCalculator(SDOShuff, dSDO, SIG_PVAL, Z_TRANSFORM); 
end

SAT.plot.getCommonCdfPlot(T, testStat, SIG_PVAL); 
pbaspect([1,1,1]);         


tString = strcat(ppName, " on ", xtName); 
switch pR.normalization
    case 'px0'
        tString = strcat('P(x0)-Normed ', tString); 
    case 'unity'
        tString = strcat('Column-Normed ', tString); 
end
if PARAMETRIC
    tString = strcat(tString, " (Parametric)"); 
else
    tString = strcat(tString, " (From Shuffled)"); 
end
if Z_TRANSFORM
    tString = {tString; ' (Z-Scored)'}; 
end

suptitle2(tString); 

    
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "2DArray_SDO_sig"); 
end
    

end