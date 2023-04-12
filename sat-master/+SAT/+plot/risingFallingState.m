%% plotSDO_risingFallingState
%Plot the coarse direction of transition of the off-diagonal components
% of the SDO
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

% Maryam Abolfath-Beygi, 2018
% Trevor S. Smith, 2022

function plotSDO_risingFallingState(sdo, XT_CH_NO, PP_CH_NO, varargin) 
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

SIG_PVAL    = sdo(XT_CH_NO).stats{PP_CH_NO}.pVal; 
N_BINS       = length(sdo(XT_CH_NO).bkgrndSDO); 

%//Plots the rising State vs. Shuffle AND the associated significance values

ppName0     = sdo(XT_CH_NO).neuronNames{PP_CH_NO}; 
ppName      = underscores2spaces(ppName0); 
xtName      = sdo(XT_CH_NO).signalType; 

sigLevels   = 1:length(sdo(XT_CH_NO).levels)-1; 

stRng = 1:N_BINS; 

mainTitle   = strcat(ppName, '\rightarrow', xtName); 

unitVal     = sdo(XT_CH_NO).stats{PP_CH_NO}.changeMeasureContSDO;
shufVal     = sdo(XT_CH_NO).stats{PP_CH_NO}.changeMeasureShuffContSDO;

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

%% TODO; 

if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "Coarse-Bias"); 
end

    
end
