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

sfields = {'L0_running', 'L1_running', 'KLD', 'logLikelihood'}; 
%sfields = {'KLD'}; 
SIG_PVAL = 0.05; 
PLOT = 1; 
N_SHUFFLES = 1000; 
STAT_TYPE = 'sum'; %['sum'/'mean'/'median'] 
% // Save Formats
SAVE_FIG = 0; 
SAVE_FMT = 'svg'; 
SAVE_DIR = ""; %C:\Users\Frog\Desktop\"; 
N_FIELDS = length(sfields); 

%// Note that we no longer are evaluting an ANOVA of the shuffled
%distributions due to the high DOFs from shuffling. 

sigStruct = struct( ... 
    'fieldName',    cell(1, N_FIELDS), ...
    'anova',        cell(1, N_FIELDS), ... 
    'multCompare',  cell(1, N_FIELDS)); 

for f = 1:N_FIELDS
    [sigStruct(f).anova, sigStruct(f).multCompare] = predictSDO_testSig(errorStruct, ...
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
    
1;

