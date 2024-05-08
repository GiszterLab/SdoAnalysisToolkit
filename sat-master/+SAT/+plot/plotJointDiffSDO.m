%% (Plot) jointDiffSDO
% Co-plot the background and spike-triggered SDO matrices from the 'sdo'
% datastructure as heatmaps. For use within the SDO Analysis Toolkit.
%
%PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%   sdo: 'sdo' structure
%   XT_SDO_CH_NO: Row index for the sdo structure, pointing to a particular
%       xtDataChannel
%   PP_SDO_CH_NO: Subindex for the sdo structure, pointing to a particular
%       ppDataChannel
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'plotJoint'      : [0/1]. If 1, plot the Joint SDOs & Differential
%               SDOs. Default = 1; 
%       'normalization'  : {'unity', 'px0', 'none'}. How to normalize prior
%           distributions for plotting
%       'filter',        : [0/1]. If 1, use a diagonal gaussian smoothing filter.  
%               Default = 1; 
%       'colormap'      : {'sdo', 'parula', 'polar'}. Default = 'sdo'
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Copyright (C) 2023  Trevor S. Smith
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

function plotJointDiffSDO(sdo,XT_CH_NO, PP_CH_NO, varargin)

normColormapType = 'sdo'; 
expectColormapType = {'sdo', 'parula', 'polar'}; 
normNormType = 'unity'; 
expectNormType  = {'none','px0', 'unity'}; 

p = inputParser; 
addParameter(p, 'filter', 1); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []);
addParameter(p, 'plotJoint', 1); 
addParameter(p, 'normalization', normNormType, ... 
    @(x) any(validatestring(x, expectNormType)) ); 
%addParameter(p, 'normalize', 1); % [0/1]; 
addParameter(p, 'colormap', normColormapType, ... 
    @(x) any(validatestring(x, expectColormapType)) ); 

parse(p, varargin{:}); 
pR = p.Results; 

FILTER      = pR.filter; 
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
%NORMALIZE   = pR.normalize; 
COLORMAP    = pR.colormap; 

plot_joints = pR.plotJoint; 
%________

N_BINS = size(sdo(XT_CH_NO).sdos{PP_CH_NO},1); 

%==================================================
% __ FRAGILE!! ___ 
%// These will need to be replace if we modify SDO struct; 
dSdoNames = {'Unit', 'Background', 'Shuffle Mean'}; 
%_______ Difference SDOs______________
dSdos = cell(1,3); 
dSdos{1} = sdo(XT_CH_NO).sdos{PP_CH_NO}; % Unit
dSdos{2} = sdo(XT_CH_NO).bkgrndSDO;      % Background; 
try
    try
        dSdos{3} = sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff_mean; 
    catch
        dSdos{3} = mean(sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff,3); % shuffle
    end
catch
    dSdos{3} = zeros(size(dSdos{1})); 
end

%________ Joint 'SDOs'_______________
jSdos = cell(1,3); 
jSdos{1} = sdo(XT_CH_NO).sdosJoint{PP_CH_NO}; 
jSdos{2} = sdo(XT_CH_NO).bkgrndJointSDO; 
try     
    try
        jSdos{3} = sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff_mean; 
    catch
        jSdos{3} = mean(sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff,3);
    end
catch
    jSdos{3} = ones(size(dSdos{1})); 
end
%==================================================
nCols = length(dSdoNames); 

if FILTER
    for c = 1:nCols
        dSdos{c} = SAT.sdoUtils.ffdiag([], 1, dSdos{c},1);
        jSdos{c} = SAT.sdoUtils.ffdiag([], 1, jSdos{c},1); 
    end
end 


f = figure; 

if plot_joints == 1
    ax = gobjects(2,nCols); 
    cArr_cell = cell(2,nCols); 
else
    ax = gobjects(1, nCols); 
    cArr_cell = cell(1,nCols); 
end

for c = 1:nCols
    %__
    sdomatrix = dSdos{c}; 
    denomMat = jSdos{c}; 
    switch pR.normalization
        case 'px0'
            sdomatrix = SAT.sdoUtils.reparameterizeSdo(sdomatrix, denomMat, jSdos{1}); % compare to diff 
            denomMat  = SAT.sdoUtils.reparameterizeSdo(denomMat, denomMat, jSdos{1});% compare to joint
        case 'unity'
            sdomatrix = SAT.sdoUtils.normsdo(sdomatrix, denomMat); 
            denomMat  = SAT.sdoUtils.normsdo(denomMat,denomMat); 
        case 'none'
            continue
            %sdomatrix = sdoMatrix; 
            %denomMat= denomMat; 
    end
    %___
    if plot_joints == 1
        matPlots = {sdomatrix, denomMat}; 
    else
        matPlots = {sdomatrix}; 
    end
    for z = 1:length(matPlots)
        ax(z,c)= subplot(length(matPlots),nCols, c+(z-1)*nCols); 
        mat = matPlots{z}; 
        imagesc(ax(z,c), mat); 
        switch COLORMAP
            case 'sdo'
                minVal = min(mat, [], 'all'); 
                maxVal = max(mat, [], 'all'); 
                cMap = SAT.sdoUtils.getSdoColormap(mat); 
                lineColor = [0,0,0]; %black
                cArr_cell{z,c} = cMap; 
            case {'parula', 'polar'}
                maxVal = max(abs(mat), [], 'all'); 
                minVal = -maxVal; 
                if strcmp(pR.colormap, 'parula')
                    cMap = parula; 
                elseif strcmp(pR.colormap, 'polar')
                    cMap = rgb_colorGen(256, 'polar'); 
                end
                cArr_cell{z,c} = cMap; 
                lineColor = [1,1,1]; %white 
        end
        % __ override for Px1|Px0
        if z == 2
            cMap = parula; 
        end
        %____
        colormap(ax(z,c), cMap); 
        clim([minVal, maxVal]);
        colorbar
        if z == 1
            suffix = ''; 
        else
            suffix = ' (Joint)';
        end
        title(strcat(underscores2spaces(dSdoNames{c}), suffix)); 
        line( [0, N_BINS], [0, N_BINS], 'color', lineColor, 'lineStyle', '--', 'lineWidth', 1.5); 
        axis square
        axis xy
        xlabel('x_0 State'); 
        ylabel('x_1 State'); 
    end
end

%________________________________

tString = strcat(sdo(XT_CH_NO).neuronNames{PP_CH_NO},' on ',sdo(XT_CH_NO).signalType); 
 switch pR.normalization
     case 'px0'
         tString = strcat("P(x_0)-Normalized ", tString); 
     case 'unity'
        tString = strcat("Unity-Normalized ", tString); 
 end

if FILTER
    tString = strcat(tString, " (filtered)"); 
end

suptitle2(tString); 

if SAVE_FIG
    %f = gcf; 
    sName = strcat(tString, " SDOs"); 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, sName); %"Diff_SDOs"); 
end

end