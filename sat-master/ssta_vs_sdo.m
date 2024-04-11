%% ssta_vs_SDO
%
% Show the spike-triggered average, mean-split, and state-dependent
% spike-triggered averages to demonstrate how averaging results in a
% less-accurate prediction of future signal behavior. 
%
% Uses the programatic methods


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

%% NOTE: 
% The -complete- datasets are necesary to reproduce the figures as they
% were plotted in the paper. 


%% HEADER VARS
%USE_TRIALS  = 1:22; 
%XT_CH_NO    = 8; 
%PP_CH_NO    = 12; 
%XT_CH_NO = 1;
%PP_CH_NO = 1; 
XT_CH_NO = 6; 
PP_CH_NO = 4; 
% __ 
N_T0_PTS = 40; 

%N_T0_PTS    = 60; %prespike n points 
%N_T1_PTS    = 100; 
N_T1_PTS    = 40; %postspike n points
N_STATES    = 40; 
MAX_MODE    = 'xTrialxSeg'; 
%MAP_METHOD  = 'log'; 
%MAP_METHOD  = 'logsigned'; 
MAP_METHOD  = 'linearsigned'; %[log,linear,logsigned,linearsigned]
%MAP_METHOD  = 'linear'; 
%___
%DATA_FIELD  = 'envelope';
DATA_FIELD = 'raw'; 

COMPOSITE   = 1; %[0/1] %/whether to assemble figures into subplot
LEVEL = 0; 
RECTIFY = 0; 

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

USE_TRIALS = 1:size(xtData,2); 

[~, xtData] = pxTools.getXtStateMap(xtData, N_STATES, ...
    'fieldname', DATA_FIELD, ...
    'maxMode', MAX_MODE, ...
    'mapMethod', MAP_METHOD); 

sigLevels = xtData{1,1}(XT_CH_NO).signalLevels; 
sigLevels = sigLevels/10; 

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
    'pxNPoints', [N_T0_PTS N_T1_PTS], ...
    'pxFilter',  [0,0], ...
    'xtDataField', DATA_FIELD); 
    
%// Flatten DataCells into N_PTS x N_SPIKES doubles arrays of signal
%amplitude around spike
at0 = flattenCell(at0Cell, XT_CH_NO, PP_CH_NO); 
at1 = flattenCell(at1Cell, XT_CH_NO, PP_CH_NO); 
px0 = flattenCell(px0Cell, XT_CH_NO, PP_CH_NO); 
px1 = flattenCell(px1Cell, XT_CH_NO, PP_CH_NO); 

%_________________________________
% evaluate statistics. 


% take the baseline RMS for excluding null-correlations; 
N_TRIALS = size(xtData,2); 
sigHz = 2000;
zArr = zeros(N_TRIALS, sigHz); 
for tr = 1:N_TRIALS
    zArr(tr,:) = xtData{1,tr}(XT_CH_NO).(DATA_FIELD)(1:sigHz); 
end

baselineThresh = rms(zArr(:))*1.25; 

at01 = [at0; at1]; 

useSpikes = any(abs(at01) > baselineThresh); 

1; 


%mean values of amplitude around spike 


if RECTIFY
    rest_mean = mean(abs(at0(1:40,:)), 'all'); 
    rest_std = mean(std(abs(at0(1:40,:)'))); 
else
    mn0 = mean(at0'); 
    mn1 = mean(at1'); 
    rest_mean = mean(mn0(1:40)); %if > 30 ms; 
    rest_std = std(mn0(1:40)); 
end

thresh_pos = rest_mean+2*rest_std; 
thresh_neg = rest_mean-2*rest_std; 


if LEVEL
    bsline = mean(at0(1:10,:)); 
    % intial state leveling
    bsArr = ones(N_T0_PTS+N_T1_PTS, length(bsline)) *  diag(bsline); 
else
    bsArr = zeros(size([at0; at1])); 
end
%
f = figure; 
if RECTIFY
    plot(abs(at01-bsArr), 'color', [0.3, 0.3, 0.3, 0.3]);
    hold on; 
    plot(mean(abs(at01-bsArr)'), 'color', 'k', 'lineWidth', 2); 
    %plot(abs([mn0, mn1]), 'color', 'k', 'lineWidth', 2); 
else
    plot(at01-bsArr, 'color', [0.3, 0.3, 0.3, 0.3]);
    hold on; 
    plot([mn0, mn1], 'color', 'k', 'lineWidth', 2); 
end
xline(N_T0_PTS, 'color', 'red', 'LineStyle', '--'); 
yline(thresh_pos, 'color', 'k', 'lineStyle', '--'); 

1; 

%}
%__________________________________


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

figure;
tiledlayout(2,3); 
nexttile; 
%% Fig 1.1 Plot Simple Spike-Triggered Average
pxTools.plot.sta_v_x(at0, at1, xOnes, 'colors', {xMap_all}, 'newFig', 0); 
title("Simple Spike-Time Average Waveform"); 

nexttile; 
%% Fig 1.2 Plot Mean-Split Spike-Triggered Average
cutoff = mean(at0(end,:));
xs = ones(1, length(at0(end,:))); 
xs(at0(end,:)>cutoff) = 2; 
pxTools.plot.sta_v_x(at0, at1, xs, 'colors', {[xMap_lo; xMap_hi]}, 'newFig', 0); 
title("Simple Spike-Time Average Waveform (Mean-Split)");

nexttile; 
%% Fig 1.3 Spike-Triggered Inpulse Responsible Probability Distribution (STIRPD)
x0 = discretize(at0, sigLevels); 
x1 = discretize(at1, sigLevels); 
pxTools.plot.staPxt(x0,x1, N_STATES, 'colorbar', 1, 'newFig', 0); 
nexttile; 

%// Find state bin corresponding to 1/2 Split; Draw distributions
LI_x0lo = at0(N_STATES,:) < cutoff; 
LI_x0hi = at0(N_STATES,:) >= cutoff; 

%% Fig 1.4 Overall pre/post spike P(x)
pxTools.plot.px([mean(px0,2), mean(px1,2)], 'colors', {[xMap_all_1; xMap_all_2]}, 'newFig', 0); 
title("Spike-triggered P(x)"); 
legend({'pre-spike', 'post-spike'}); 

nexttile; 
%% Fig 1.5 Low-Half pre/post spike P(x)
pxTools.plot.px([mean(px0(:,LI_x0lo),2), mean(px1(:,LI_x0lo),2)], 'colors', {[xMap_lo_1; xMap_lo_2]}, 'newFig', 0); 
title("Mean-Split Spike-triggered P(x) (Lower)"); 
legend({'pre-spike', 'post-spike'}); 

nexttile; 
%% Fig 1.6 Hi-Half pre/post spike P(x)
%subplot(2,3,6); 
pxTools.plot.px([mean(px0(:,LI_x0hi),2), mean(px1(:,LI_x0hi),2)], 'colors', {[xMap_hi_1; xMap_hi_2]}, 'newFig', 0); 
title("Mean-Split Spike-triggered P(x) (Upper)");


%% Replicate for Background/Shuffles
%// Draw an equivalent amount of observations to estimate background
%ppDataCellShuff = ppData; 
ppDataCellShuff = SAT.ppDataHolder_new(size(ppData,2), PP_CH_NO); 


for tr = 1:max(USE_TRIALS)
    if ~ismember(tr, USE_TRIALS) 
        continue 
    end 
    try
        spks = ppData{1,tr}(PP_CH_NO).times; 
    catch 
        %// old-legacy
        spks = ppData{1,tr}(PP_CH_NO).time; 
    end
    maxTime = max(spks);
    %maxTime = xtData{1,tr}(1).times(end); 
    getCounts = length(spks);
    if ~isempty(spks)
        %ppDataCellShuff{1,tr}(PP_CH_NO).times = shuffleSpikesInsideRange(spks, spks(1), spks(end),1); 
        ppDataCellShuff{1,tr}(PP_CH_NO).times = sort(rand(1,getCounts)*floor(maxTime)); 
    end
end
[px0ShuffCell,px1ShuffCell,~,~,at0ShuffCell, at1ShuffCell] = pxTools.getTrialwisePxt( ... 
    xtData, ppDataCellShuff, ...
    'trList', USE_TRIALS, ...
    'xtList', XT_CH_NO, ...
    'ppList', PP_CH_NO, ...
    'pxNPoints', [N_T0_PTS N_T1_PTS], ...
    'pxFilter',  [0,0], ...
    'xtDataField', DATA_FIELD); 

at0Shuff = flattenCell(at0ShuffCell, XT_CH_NO, PP_CH_NO); 
at1Shuff = flattenCell(at1ShuffCell, XT_CH_NO, PP_CH_NO); 
px0Shuff = flattenCell(px0ShuffCell, XT_CH_NO, PP_CH_NO); 
px1Shuff = flattenCell(px1ShuffCell, XT_CH_NO, PP_CH_NO); 


figure;
tiledlayout(2,3); 
nexttile; 
%% Fig 2.1 Simple STA of Shuffles
pxTools.plot.sta_v_x(at0Shuff, at1Shuff, xOnes, 'colors', {xMap_all}, 'newFig', 0); 
title("Simple Spike-Shuffled Average Waveform"); 

nexttile; 
%% Fig 2.2 Mean-Split STA of Shuffles
xs = ones(1, length(at0Shuff(end,:))); 
xs(at0Shuff(end,:)>cutoff) = 2; 
pxTools.plot.sta_v_x(at0Shuff, at1Shuff, xs, 'colors', {[xMap_lo; xMap_hi]}, 'newFig', 0); 
title("Simple Spike-Shuffled Average Waveform (Mean-Split)"); 

nexttile; 
%% Fig 2.3 Spike-Triggered Impulse Response Distribution
x0Shuff = discretize(at0Shuff,sigLevels); 
x1Shuff = discretize(at1Shuff,sigLevels); 
pxTools.plot.staPxt(x0Shuff, x1Shuff, N_STATES, 'colorbar', 1, 'newFig', 0)

% //  Repeat for background/Shuffles
LI_Shflo = at0Shuff(N_STATES,:) < cutoff; 
LI_Shfhi = at0Shuff(N_STATES,:) >= cutoff;  

nexttile; 
%% Figure 2.4 Overall Pre/Post P(x) of Shuffles
pxTools.plot.px([mean(px0Shuff,2), mean(px1Shuff,2)], 'colors', {[xMap_all_1; xMap_all_2]}, 'newFig', 0); 
title("Background Pre/Post Spike p(x)"); 

nexttile; 
%% Figure 2.5 Lower-half P(x) Pre/Post of Shuffles
pxTools.plot.px([mean(px0Shuff(:,LI_Shflo),2), mean(px1Shuff(:,LI_Shflo),2)], 'colors', {[xMap_lo_1; xMap_lo_2]}, 'newFig', 0);   
title("Background Mean-Split p(x) (Lower)");

nexttile; 
%% Figure 3.6 Upper-half P(x) Pre/Post of Shuffles
pxTools.plot.px([mean(px0Shuff(:,LI_Shfhi),2), mean(px1Shuff(:,LI_Shfhi),2)], 'colors', {[xMap_hi_1; xMap_hi_2]}, 'newFig', 0); 
title("Background Mean-Split p(x) (Upper)");

%% Varspace Cleanup
%{
clear at0 at0Cell at0Shuff at0ShuffCell at1 at1Cell at1Shuff at1ShuffCell cutoff
clear DATA_FIELD fdir1 fdir2 ffile1 ffile2 fnew fpath_pp fpath_xt getCounts i LI_Shfhi
clear LI_Shflo LI_x0hi LI_x0lo MAP_METHOD MAX_MODE maxTime N_STATES N_T0_PTS
clear PP_CH_N0 ppDataCell0 ppDataCellShuff ppfield px0 px0Cell px0Shuff px0ShuffCell
clear ppDataCell0 ppDataCellShuff ppfield px0 px0Cell px0Shuff px0ShuffCell px1 px1Cell 
clear px1Shuff px1ShuffCell ax a1_copy px1ShuffCell
clear sigLevels spks tr USE_TRIALS x0 x0Shuff x1 x1Shuff xMap_all xMap_all_1 xMap_all_2
clear xMap_hi xMap_hi_1 xMap_hi_2 xMap_lo xMap_lo_1 xMap_lo_2 xOnes xs XT_CH_NO
clear xtDataCell0 xtfield COMPOSITE
%}

%% Auxillary Functions

function flatArr = flattenCell(cellArr, m, u)
    tmp = cell(1, length(cellArr)); 
    for tr = 1:length(cellArr)
        if isempty(cellArr{tr})
            continue; 
        end
        tmp{tr} = cellArr{tr}{m,u}; 
    end
    flatArr = cellhcat(tmp); 

%    tmp = cellzcat(cellArr); 

    %cl_1     = cellhcat(cellArr); 
    %cl_2    = cellhcat(cl_1); 
    %cl_2     = cellvcat(c1_1); 
    %flatArr = cellhcat(cl_2); 
end
