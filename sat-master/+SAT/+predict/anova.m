%% predictSDO_anova
% Stand-alone header for testing the stats within the errorStruct; 
% Take observed prediction errors, paired-point bootstrap to produce
% distributions w/ confidence intervals, and evaluate differences in a
% chosen test statistic (sum, mean, median) across shuffles to evaluate
% significance.
% --> Use innate MATLAB stats packages 
% --> This test should universally work for both distribution-wise and
% single-state errors
%
% NOTE: We are taking bootstraps of some derivation of the test statistic
% (etc. sum, mean, median), which is testing for significance of
% DISTRIBUTION-WISE metrics. Individual elements of EVENT-WISE error may
% differ by hypothesis (and distributions of these eventwise errors may
% overlap, even if the distributionwise metrics do not). 

% Trevor S. Smith, 2023
% Drexel University College of Medicine

function anova(errorStruct, varargin)
p = inputParser; 
%addParameter(p, '
addParameter(p, 'pVal', 0.05); 
addParameter(P, 'nShuffles', 1000); 
addParameter(p, 'statType', 'sum'); %['sum'/'mean'/'median'] 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
addParameter(p, 'plotProp',0); 
parse(p, varargin{:}); 
pR = p.Results; 

% // Save Formats
SIG_PVAL    = pR.pVal; 
SAVE_FIG    = pR.saveFig;  
SAVE_FMT    = pR.saveFormat;
SAVE_DIR    = pR.outputDirectory; 
STAT_TYPE   = pR.statType; 
N_SHUFFLES  = pR.nShuffles; 

sfields = {'L0_running', 'L1_running', 'KLD', 'logLikelihood'}; 

N_FIELDS = length(sfields); 

if isstruct(pR.plotProp) 
    %CUSTOM_PLOT = 1; 
    plotProp = pR.plotProp; 
else
    %CUSTOM_PLOT = 0; 
    plotProp = []; 
end


%// Note that we no longer are evaluting an ANOVA of the shuffled
%distributions due to the high DOFs from shuffling. 

sigStruct = struct( ... 
    'fieldName',    cell(1, N_FIELDS), ...
    'anova',        cell(1, N_FIELDS), ... 
    'multCompare',  cell(1, N_FIELDS)); 

for f = 1:N_FIELDS
    [sigStruct(f).anova, sigStruct(f).multCompare] = SAT.predict.testSig(errorStruct, ...
        'pVal',         SIG_PVAL, ... 
        'nShuffles',    N_SHUFFLES, ... 
        'dataField',    sfields{f}, ...
        'statType',     STAT_TYPE, ...  
        'plotProp',     plotProp, ... 
        'saveFig',      SAVE_FIG, ... 
        'saveFormat',   SAVE_FMT, ... 
        'outputDirectory', SAVE_DIR); 
    sigStruct(f) = sfields{f}; 
end
    

end

