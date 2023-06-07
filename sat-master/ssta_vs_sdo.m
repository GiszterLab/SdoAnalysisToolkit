%% ssta_vs_SDO
%
% Show the spike-triggered average, mean-split, and state-dependent
% spike-triggered averages to demonstrate how averaging results in a
% less-accurate prediction of future signal behavior. 

%_______________________________________
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
%__________________________________________


%% HEADER VARS
USE_TRIALS  = 1:22; 
%XT_CH_NO    = 8; 
%PP_CH_NO    = 12; 
XT_CH_NO = 6; 
PP_CH_NO = 4; 
% __ 
N_T0_PTS    = 20; 
N_STATES    = 20; 
MAX_MODE    = 'xTrialxSeg'; 
MAP_METHOD  = 'log'; 
%___
DATA_FIELD  = 'envelope';

COMPOSITE   = 1; %[0/1] %/whether to assemble figures into subplot

%% _________

%// Grab 'xtData' and 'ppData', or confirm loaded into memory
if ~exist('xtData', 'var') || ~exist('ppData', 'var')
    [fpath_xt, fdir1] = uigetfile('*.mat', 'Open example xtData'); 
    [fpath_pp, fdir2] = uigetfile('*.mat', 'Open example ppData'); 

    ffile1 = fullfile(fdir1, fpath_xt); 
    ffile2 = fullfile(fdir2, fpath_pp); 

    xtDataCell0 = load(ffile1); 
    ppDataCell0 = load(ffile2); 
    xtfield = fields(xtDataCell0); 
    ppfield = fields(ppDataCell0); 
    xtData = xtDataCell0.(xtfield{1}); 
    ppData = ppDataCell0.(ppfield{1}); 
end

[~, xtData] = pxTools.getXtStateMap(xtData, N_STATES, ...
    'maxMode', MAX_MODE, ...
    'mapMethod', MAP_METHOD); 

sigLevels = xtData{1,1}(XT_CH_NO).signalLevels; 

%// refresh necessary for re-manipulating figures
close all

%// Define State as rasterized amplitude; append definitions to xtData
[~, xtData] = pxTools.getXtStateMap(xtData, N_STATES, ...
    'maxMode', MAX_MODE, ...
    'mapMethod', MAP_METHOD); 

%// Grab signal amplitudes around spike, using the pxTools library
[px0Cell,px1Cell,~,~,at0Cell, at1Cell] = pxTools.getTrialwisePxt( ... 
    xtData, ppData, ...
    'trList', USE_TRIALS, ...
    'xtList', XT_CH_NO, ...
    'ppList', PP_CH_NO, ...
    'pxNPoints', [N_T0_PTS N_T0_PTS], ...
    'pxFilter',  [0,0], ...
    'xtDataField', DATA_FIELD); 
    
%// Flatten DataCells into N_PTS x N_SPIKES doubles arrays of signal
%amplitude around spike
at0 = flattenCell(at0Cell); 
at1 = flattenCell(at1Cell); 
px0 = flattenCell(px0Cell); 
px1 = flattenCell(px1Cell); 

xOnes = ones(size(at0(end,:))); 

%// Custom ColorMaps Matching figure legends
xMap_all = [162, 113, 201]/255; 
xMap_all_1= [200, 60, 255]/255; 
xMap_all_2= [182,133, 221]/255; 
xMap_hi  = [223, 143,  72]/255; 
xMap_hi_1= [255,  60,  50]/255; 
xMap_hi_2= [252, 137,  36]/255; 
xMap_lo  = [ 60, 150, 210]/255; 
xMap_lo_1= [ 41, 154, 255]/255; 
xMap_lo_2= [ 80, 183, 219]/255; 


%% Fig 1.1 Plot Simple Spike-Triggered Average
pxTools.plot.sta_v_x(at0, at1, xOnes, 'colors', {xMap_all}); 
title("Simple Shuffled-Time Average Waveform"); 

%% Fig 1.2 Plot Mean-Split Spike-Triggered Average
cutoff = mean(at0(end,:));
xs = ones(1, length(at0(end,:))); 
xs(at0(end,:)>cutoff) = 2; 
pxTools.plot.sta_v_x(at0, at1, xs, 'colors', {[xMap_lo; xMap_hi]}); 
title("Simple Shuffled-Time Average Waveform (Mean-Split)");

%% Fig 1.3 Spike-Triggered Inpulse Responsible Probability Distribution (STIRPD)
x0 = discretize(at0, sigLevels); 
x1 = discretize(at1, sigLevels); 
pxTools.plot.staPxt(x0,x1, N_STATES, 'colorbar', 1); 

%// Find state bin corresponding to 1/2 Split; Draw distributions
LI_x0lo = at0(N_STATES,:) < cutoff; 
LI_x0hi = at0(N_STATES,:) >= cutoff; 

%% Fig 1.4 Overall pre/post spike P(x)
pxTools.plot.px([mean(px0,2), mean(px1,2)], 'colors', {[xMap_all_1; xMap_all_2]}); 
title("Spike-triggered P(x)"); 
legend({'pre-spike', 'post-spike'}); 

%% Fig 1.5 Low-Half pre/post spike P(x)
pxTools.plot.px([mean(px0(:,LI_x0lo),2), mean(px1(:,LI_x0lo),2)], 'colors', {[xMap_lo_1; xMap_lo_2]}); 
title("Mean-Split Spike-triggered P(x) (Lower)"); 
legend({'pre-spike', 'post-spike'}); 

%% Fig 1.6 Hi-Half pre/post spike P(x)
pxTools.plot.px([mean(px0(:,LI_x0hi),2), mean(px1(:,LI_x0hi),2)], 'colors', {[xMap_hi_1; xMap_hi_2]}); 
title("Mean-Split Spike-triggered P(x) (Upper)");


%// Re-assemble figures into expected order (as in paper)
if COMPOSITE
    fnew = figure; 
    for i = 1:6
        figure(i); 
        ax = gca; 
        a1_copy  = copyobj(ax,fnew); 
        %a1_copy = copyobj(f, fnew);
        subplot(2,3,i,a1_copy); 
        if i > 3
            legend(ax, {'pre-spike', 'post-spike'}); 
        end 
        close(i); 
    end
     set(gcf, 'Position', get(0, 'Screensize'));
end
 
%% Replicate for Background/Shuffles
%// Draw an equivalent amount of observations to estimate background
ppDataCellShuff = ppData; 
for tr = 1:max(USE_TRIALS)
    if ~ismember(tr, USE_TRIALS) 
        continue 
    end 
    spks = ppData{1,tr}(PP_CH_NO).time; 
    maxTime = max(spks); 
    getCounts = length(spks);
    if ~isempty(spks)
        ppDataCellShuff{1,tr}(PP_CH_NO).time = sort(rand(1,getCounts)*floor(maxTime)); 
    end
end
[px0ShuffCell,px1ShuffCell,~,~,at0ShuffCell, at1ShuffCell] = pxTools.getTrialwisePxt( ... 
    xtData, ppDataCellShuff, ...
    'trList', USE_TRIALS, ...
    'xtList', XT_CH_NO, ...
    'ppList', PP_CH_NO, ...
    'pxNPoints', [N_T0_PTS N_T0_PTS], ...
    'pxFilter',  [0,0], ...
    'xtDataField', DATA_FIELD); 

at0Shuff = flattenCell(at0ShuffCell); 
at1Shuff = flattenCell(at1ShuffCell); 
px0Shuff = flattenCell(px0ShuffCell); 
px1Shuff = flattenCell(px1ShuffCell); 

%% Fig 2.1 Simple STA of Shuffles
pxTools.plot.sta_v_x(at0Shuff, at1Shuff, xOnes, 'colors', {xMap_all}); 
title("Simple Spike-Triggered Average Waveform"); 

%% Fig 2.2 Mean-Split STA of Shuffles
xs = ones(1, length(at0Shuff(end,:))); 
xs(at0Shuff(end,:)>cutoff) = 2; 
pxTools.plot.sta_v_x(at0Shuff, at1Shuff, xs, 'colors', {[xMap_lo; xMap_hi]}); 
title("Simple Spike-Triggered Average Waveform (Mean-Split)"); 

%% Fig 2.3 Spike-Triggered Impulse Response Distribution
x0Shuff = discretize(at0Shuff,sigLevels); 
x1Shuff = discretize(at1Shuff,sigLevels); 
pxTools.plot.staPxt(x0Shuff, x1Shuff, N_STATES, 'colorbar', 1)

% //  Repeat for background/Shuffles
LI_Shflo = at0Shuff(N_STATES,:) < cutoff; 
LI_Shfhi = at0Shuff(N_STATES,:) >= cutoff;  

%% Figure 2.4 Overall Pre/Post P(x) of Shuffles
pxTools.plot.px([mean(px0Shuff,2), mean(px1Shuff,2)], 'colors', {[xMap_all_1; xMap_all_2]}); 
title("Background Pre/Post Spike p(x)"); 

%% Figure 2.5 Lower-half P(x) Pre/Post of Shuffles
pxTools.plot.px([mean(px0Shuff(:,LI_Shflo),2), mean(px1Shuff(:,LI_Shflo),2)], 'colors', {[xMap_lo_1; xMap_lo_2]});   
title("Background Mean-Split p(x) (Lower)");

%% Figure 3.6 Upper-half P(x) Pre/Post of Shuffles
pxTools.plot.px([mean(px0Shuff(:,LI_Shfhi),2), mean(px1Shuff(:,LI_Shfhi),2)], 'colors', {[xMap_hi_1; xMap_hi_2]}); 
title("Background Mean-Split p(x) (Upper)");

%// Re-assemble figures into expected order (as in paper)
if COMPOSITE
    fnew = figure; 
    for i = 1:6
        figure(i); 
        ax = gca; 
        a1_copy  = copyobj(ax,fnew); 
        subplot(2,3,i,a1_copy); 
        close(i); 
    end
    set(gcf, 'Position', get(0, 'Screensize'));
end

%% Varspace Cleanup
clear at0 at0Cell at0Shuff at0ShuffCell at1 at1Cell at1Shuff at1ShuffCell cutoff
clear DATA_FIELD fdir1 fdir2 ffile1 ffile2 fnew fpath_pp fpath_xt getCounts i LI_Shfhi
clear LI_Shflo LI_x0hi LI_x0lo MAP_METHOD MAX_MODE maxTime N_STATES N_T0_PTS
clear PP_CH_N0 ppDataCell0 ppDataCellShuff ppfield px0 px0Cell px0Shuff px0ShuffCell
clear ppDataCell0 ppDataCellShuff ppfield px0 px0Cell px0Shuff px0ShuffCell px1 px1Cell 
clear px1Shuff px1ShuffCell ax a1_copy px1ShuffCell
clear sigLevels spks tr USE_TRIALS x0 x0Shuff x1 x1Shuff xMap_all xMap_all_1 xMap_all_2
clear xMap_hi xMap_hi_1 xMap_hi_2 xMap_lo xMap_lo_1 xMap_lo_2 xOnes xs XT_CH_NO
clear xtDataCell0 xtfield COMPOSITE

%% Auxillary Functions

function flatArr = flattenCell(cellArr)
    c1_1     = cellhcat(cellArr); 
    cl_2     = cellvcat(c1_1); 
    flatArr = cellhcat(cl_2); 
end
