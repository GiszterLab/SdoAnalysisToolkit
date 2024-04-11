%% (Plot) diffSDO
% Coplots spike-triggered, background, and shuffled split symmetric SDOS;
% Drift components correspond to the directional shifts (mean) while diffusion
% corresponds to the nondirectional (variance)
%
%
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
%       'filter',        : [0/1]. If 1, use a diagonal gaussian smoothing filter.  
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Requires MATLAB 2019 or newer


% Copyright (C) 2024  Trevor S. Smith
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

function plotSplitSymmetrySDO(sdoStruct,XT_CH_NO, PP_CH_NO, vars)%, varargin)
arguments
    sdoStruct
    XT_CH_NO = 1; 
    PP_CH_NO = 1; 
    vars.filter = 1; 
    vars.saveFig = 0; 
    vars.saveFormat {mustBeMember(vars.saveFormat, {'png', 'svg'})} = 'png'; 
    vars.outputDirectory = []; 
    % vars.normalize = 0; 
    vars.normalization {mustBeMember( vars.normalization, {'px0', 'unity', 'none'})} = 'none'; 
    vars.colormap {mustBeMember(vars.colormap, {'sdo', 'parula', 'polar'})} = 'sdo'; 
end
FILTER      = vars.filter; 
SAVE_FIG    = vars.saveFig; 
SAVE_FMT    = vars.saveFormat;
SAVE_DIR    = vars.outputDirectory; 
%________

N_BINS = size(sdoStruct(XT_CH_NO).sdos{PP_CH_NO},1); 

%==================================================
% __ FRAGILE!! ___ 
%// These will need to be replace if we modify SDO struct; 
dSdoNames = {'Unit', 'Background', 'Shuffle Mean'}; 
%_______ Difference SDOs______________
dSdos = cell(1,3); 
dSdos{1} = sdoStruct(XT_CH_NO).sdos{PP_CH_NO}; % Unit
dSdos{2} = sdoStruct(XT_CH_NO).bkgrndSDO;      % Background; 
try
    try
        dSdos{3} = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff_mean; 
    catch
        dSdos{3} = mean(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff,3); % shuffle
    end
catch
    dSdos{3} = zeros(size(dSdos{1})); 
end

%________ Joint 'SDOs'_______________
jSdos = cell(1,3); 
jSdos{1} = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO}; 
jSdos{2} = sdoStruct(XT_CH_NO).bkgrndJointSDO; 
try 
    try
        jSdos{3} = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff_mean; 
    catch
        jSdos{3} = mean(sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff,3); 
    end
catch
    jSdos{3} = ones(size(dSdos{1})); 
end
%==================================================
nCols = length(dSdoNames); 

% __>> Asymmetrization should precede normalization__ 
matCell = cell(2,nCols); 
%{
for n = 1:nCols
    [drf,dff] = SAT.sdoUtils.splitSymmetry(dSdos{n}); 
    %
    matCell{1,n} = drf; 
    matCell{2,n} = dff; 
end
%}

if FILTER
    for c = 1:nCols
        dSdos{c} = SAT.sdoUtils.ffdiag([], 1, dSdos{c},1); 
        jSdos{c} = SAT.sdoUtils.ffdiag([], 1, jSdos{c},1); 
    end
end


f = figure; 
ax = gobjects(2, nCols); 

cArr_cell = cell(2,nCols); 

t =tiledlayout(2, nCols); 
t.TileIndexing = 'columnmajor'; 

for c = 1:nCols 
    %
    switch vars.normalization
        case 'px0'
            sdomatrix = SAT.sdoUtils.reparameterizeSdo(dSdos{c}, jSdos{c}, jSdos{1}); 
        case 'unity'
            sdomatrix = SAT.sdoUtils.normsdo(dSdos{c}, jSdos{c}); 
        case 'none'
            sdomatrix = dSdos{c}; 
    end
    %}
    %
    
    [drft_mat, diff_mat] = SAT.sdoUtils.splitSymmetry(sdomatrix);

    matCell(:,c) = {drft_mat, diff_mat}'; 
    %}
    for z = 1:2
        ax(z,c) = nexttile; 
        sdomat = matCell{z,c}; 

        %{
        if FILTER
            sdomatrix = SAT.sdoUtils.ffdiag([],1,sdomatrix,1); 
            denomMat  = SAT.sdoUtils.ffdiag([],1,jSdos{c}); 
        else
            denomMat = jSdos{c}; 
        end

        if vars.normalize
            sdomatrix = SAT.sdoUtils.normsdo(sdomatrix, denomMat); 
        end        
           %}

        imagesc(sdomatrix);  
        switch vars.colormap
            case 'sdo'
                maxVal = max(sdomat, [], 'all'); 
                minVal = min(sdomat, [], 'all'); 
                cMap = SAT.sdoUtils.getSdoColormap(sdomat); 
                lineColor = [0,0,0]; %black
                cArr_cell{1,c} = cMap; 
            case {'parula', 'polar'}
                maxVal = max(abs(sdomat), [], 'all'); 
                minVal = -maxVal; 
                if strcmp(vars.colormap, 'parula')
                    cMap = parula; 
                elseif strcmp(vars.colormap, 'polar')
                    cMap = rgb_colorGen(256, 'polar'); 
                end
                cArr_cell{1,c} = cMap; 
                lineColor = [1,1,1]; %white 
        end
        colormap(ax(z,c), cMap); 
        clim([minVal, maxVal]); 
        colorbar
        line( [0, N_BINS], [0, N_BINS], 'color', lineColor, 'lineStyle', '--', 'lineWidth', 1.5); 
        axis square
        axis xy
        xlabel('x_0 State'); 
        ylabel('x_1 State');
        if z == 1
            title(strcat("Drift-SDO::", dSdoNames{c})); 
        else
            title(strcat("Diffusion SDO::", dSdoNames{c})); 
        end
    end
end

tString = strcat(sdoStruct(XT_CH_NO).neuronNames{PP_CH_NO}," on ",sdoStruct(XT_CH_NO).signalType, "; Drift v. Diffusion"); 
switch vars.normalization
     case 'px0'
         tString = strcat("P(x_0)-Normalized ", tString); 
     case 'unity'
        tString = strcat("Unity-Normalized ", tString); 
end

if FILTER
    tString = strcat(tString, " (Filtered)"); 
end

title(t, tString); 

if SAVE_FIG
    %f = gcf; 
    sName = strcat(tString, " SplitSymmetric_SDOs"); 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, sName); %"SplitSymmetric_SDOs"); 
end

end