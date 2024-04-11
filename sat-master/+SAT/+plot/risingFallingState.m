%% plotSDO_risingFallingState
%Plot the coarse direction of transition of the off-diagonal components
% of the SDO. For use within the SDO Analysis Toolkit. 
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
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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

function risingFallingState(sdoStruct, XT_CH_NO, PP_CH_NO, varargin) 
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
%________

% __ Extract common vals; 

SIG_PVAL    = sdoStruct(XT_CH_NO).stats{PP_CH_NO}.pVal; 
N_BINS       = length(sdoStruct(XT_CH_NO).bkgrndSDO); 

%//Plots the rising State vs. Shuffle AND the associated significance values

ppName0     = sdoStruct(XT_CH_NO).neuronNames{PP_CH_NO}; 
ppName      = underscores2spaces(ppName0); 
xtName      = sdoStruct(XT_CH_NO).signalType; 

sigLevels   = 1:length(sdoStruct(XT_CH_NO).levels)-1; 

stRng = 1:N_BINS; 

mainTitle   = strcat(ppName, '\rightarrow', xtName); 

% __>> We can stream this from the new stats struct; 

unitVal = matTriangle_up_down_difference(sdoStruct(XT_CH_NO).sdos{PP_CH_NO}); 
%shuff_px0 = unit_px0+

[~,~,rdSdo,~] = SAT.sdoUtils.get_UnitBkgdShuff_Matrices(sdoStruct, XT_CH_NO, PP_CH_NO);
shufVal = matTriangle_up_down_difference(rdSdo.Shuff); 

%matTriangle_up_down_difference(dSdo.(x1) );

% ___ TODO: Add these in here from new stats struct; 

%unitVal     = sdo(XT_CH_NO).stats{PP_CH_NO}.changeMeasureContSDO;
%shufVal     = sdo(XT_CH_NO).stats{PP_CH_NO}.changeMeasureShuffContSDO;

meanShuff    = mean(shufVal,3); 
stdShuff     = std( shufVal, 0,3); 

bonFerrpVal=SIG_PVAL/N_BINS;
zScore = norminv(1-bonFerrpVal/2); %// effectively the number of STDs representing this percentile
Z_SHUFF = zScore*stdShuff; 

if ~isempty(Z_SHUFF)
    sigGrtr=find(unitVal>meanShuff+Z_SHUFF);
    sigLowr=find(unitVal<meanShuff-Z_SHUFF);
    USED_SHUFF = 1; 
else
    sigGrtr     = []; 
    sigLowr     = []; 
    USED_SHUFF  = 0; 
    SIG_PVAL    = 0; 
end
%% Stats-Sig
[~, ssqrd, stat]=sigSSquaredCalculator(shufVal,unitVal,SIG_PVAL); 
figure; 
%_____________ Rising/Falling State
subplot(1,2,1);
hold on; 

plot(sigLevels(stRng),unitVal,'linewidth',3,'color','r'); 

if USED_SHUFF
    errorbar(sigLevels(stRng),meanShuff,Z_SHUFF,'linewidth',1,'color','b'); 
else
    plot(1:N_BINS,zeros(1,N_BINS), 'color', 'k'); 
end
    
leg={['Rising rate at' '\bf t_s'],'Baseline rising rate'};

if ~isempty(sigGrtr)
    plot(sigLevels(sigGrtr),unitVal(sigGrtr),'^g','markersize',7,'MarkerFaceColor','g')
    leg{end+1}='Significantly Higher';
end
if ~isempty(sigLowr)
    plot(sigLevels(sigLowr),unitVal(sigLowr),'vk' ,'markersize',7,'MarkerFaceColor','k')
    leg{end+1}='Significantly Lower';
end
hold off
title(mainTitle)

ylabel('\Sigma(Higher) - \Sigma(Lower) P(x_1|x_0)'); 
xlabel('Current State level')%, ylabel([emgName ' Rising Freq'])
legend(leg)
    
%___________ Sig-Stats

subplot(1,2,2);

SAT.plot.getCommonCdfPlot(ssqrd, stat, SIG_PVAL)

suptitle2(strcat(ppName, " on ", xtName)); 

%% WRITEOUT

if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "Coarse-Bias"); 
end

    
end
