%% (predictSDO) testSig
% Extension to testing significance for error rates within the
% 'ErrorStruct' standard structure for predictions
%
% E1 is effectively a binomial distribution -- The only thing we can test 
% is the frequency of the error v. the total number of events. 
%
% E2 and E3 are effectively half-normal distributions. We can test two
% things: 
% 1) The mean error between two elements is significantly
% different [although this is often intuitively obvious] 
% 2) The incident-wise E1 error has a 'different distribution' 
% INPUTS
%   'errorStruct' - The datastructure containing data information for the
%                   prediction. 
% OPTIONAL NAME-VALUE PAIRS: 
%   - pVal          - Doubles (0-1); Mimimum threshold for 'significance'
%   - nShuffles     - Integer. Number of shuffles to generate. 
%   - compRows      - Integer/Row indicies corresponding to specific
%       hypotheses. If not provided, will test over all rows/hypotheses.
%   - dataField     - String/Char. Name of error metric (field) to test. 
%   - statType       - ['sum'/'mean'/'median'] Default 'sum' 
%   - plotCohen     - [0/1]; Whether to display Cohen's D Statistic
%       (effect size) as a uiTable
%   - plotProp      - Structure containing the common plotter properties for the hypotheses
%   - saveFig       - [0/1]; whether to trigger the save module
%   - saveFormat    - ['png'/'svg'] 
%   - outputDirectory- String containing path. If not provided, will
%           query user
%
% OUTPUTS: 
%   anova_cll       - {1 x N Hypotheses} Cell array containing the tabular 
%       output of a 1-way ANOVA between shuffled distributions. 
%   multicomp_cll   - {1 x N_Hypotheses} Cell array containing the post-hoc
%       multiple comparisons tabular output data. 

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

function [anova_cll,multcomp_cll]= testSig(errorStruct, varargin)
p = inputParser; 
addParameter(p, 'pVal', 0.05); 
addParameter(p, 'nShuffles', 1000); 
addParameter(p, 'compRows', 1:length(errorStruct)); 
addParameter(p, 'dataField', 'L1_running'); 
addParameter(p, 'statType', 'sum'); 
    %['sum', 'mean', 'median];
addParameter(p', 'plotCohen', 0); 
addParameter(p, 'plotProp',0); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

P_VAL       = pR.pVal; 
COMP_ROWS   = pR.compRows; 
N_SHUFFLES  = pR.nShuffles; 
DATA_FIELDS = pR.dataField; 
STAT_TYPE   = pR.statType; 
PLOT_COHEN  = pR.plotCohen; 
%
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

%// toggle custom line properties for Prediction Hypotheses
if isstruct(pR.plotProp) 
    plotProp = pR.plotProp; 
else
    plotProp = []; 
end
if isstruct(plotProp)
    CUSTOM_PLOT = 1; 
else
    CUSTOM_PLOT = 0; 
end

% __ CORE LOOP
if ~iscell(DATA_FIELDS)
    DATA_FIELDS = {DATA_FIELDS}; 
end

%// for multi-test; 
N_FIELDS = length(DATA_FIELDS); 

anova_cll   = cell(1,N_FIELDS); 
multcomp_cll= cell(1,N_FIELDS); 

for ff = 1:N_FIELDS
    FIELD_NAME = DATA_FIELDS{ff}; 
    %// for every field we are testing; 
    N_SPIKES    = length(errorStruct(1).(FIELD_NAME)); 
    hhError = reshape([errorStruct(COMP_ROWS).(FIELD_NAME)], N_SPIKES, []); 
    shuffError = pairedresample(hhError, N_SHUFFLES); 
    %
    % || this is the operational distribution; 
    switch STAT_TYPE
        case {'sum', 'Sum'}
            errorDist = squeeze(sum(shuffError, 1))';
        case {'mean', 'Mean'}
            errorDist = squeeze(mean(shuffError, 1))'; 
        case {'median', 'Median'}
            errorDist = squeeze(median(shuffError, 1))'; 
    end
    % || 
    try
        hhNames= {errorStruct(COMP_ROWS).fieldname};
    catch
        hhNames = COMP_ROWS; 
    end       
    %
    %// Get Cohen's D eFfect size; 
    if PLOT_COHEN
        pxTools.getCohenD(errorDist, 1, hhNames); 
    end

    eMin = floor(min(min(errorDist))) - 1; %ensure we have endpoints
    eMax = ceil(max(max(errorDist))) + 1;  %ensure we have endpoints
    
    N_HH = length(hhNames); 
    
    edfArr = zeros(eMax-eMin, N_HH); 
    for xi = 1:(eMax-eMin) 
        edfArr(xi,:) = sum(errorDist < eMin+xi)/N_SHUFFLES; 
    end
    xBar = mean(errorDist); 
    CI  = zeros(1, N_HH); 
    
    for hh = 1:N_HH
        rowPos = find(edfArr(:,hh) > 1-P_VAL,1); 
        try
            CI(hh) = eMin+rowPos-xBar(hh);
        catch
            CI(hh) = 0; 
        end
    end
        
    %sBar = std(sumErrorDist); 
    %
    f = figure;
    if CUSTOM_PLOT == 1
        for hh = 1:N_HH
        fName   = hhNames{hh}; 
        pC      = plotProp.(fName).color; 
        pLS     = plotProp.(fName).LineStyle; 
        pLW     = plotProp.(fName).LineWidth; 
        plot(edfArr(:,hh), 'color', pC, 'Marker', 'none', 'LineStyle', pLS, 'LineWidth', pLW); 
        hold on
        end
    else
        plot(edfArr); 
    end
    hold on; 
    errorbar(xBar-eMin, 0.5*ones(1, N_HH), CI, 'horizontal', 'LineStyle', 'none', 'color', 'k');  
    xticklabels(xticks+eMin); 
    ylabel("p(Error < X| Hypothesis)"); 
    xlabel(strcat(STAT_TYPE, " Error")); 
    FNAME_PRINT = underscores2spaces(FIELD_NAME); 
    
    title(strcat(STAT_TYPE, " ", FNAME_PRINT, " EDF w/ ", num2str((1-P_VAL)*100), "% CI")); 
    legend(hhNames); 
    
    f2 = figure; 
    if CUSTOM_PLOT == 1
        for hh = 1:N_HH
        fName   = hhNames{hh}; 
        pC      = plotProp.(fName).color; 
        pLS     = plotProp.(fName).LineStyle; 
        pLW     = plotProp.(fName).LineWidth; 
        plot(diff(edfArr(:,hh)), 'color', pC, 'Marker', 'none', 'LineStyle', pLS, 'LineWidth', pLW); 
        hold on
        end
    else
        plot(diff(edfArr)); 
    end    
    xticklabels(xticks+eMin); 
    xlabel("Cumulative Error"); 
    ylabel("p(Error)"); 
    title(strcat(STAT_TYPE, " ", FNAME_PRINT, " BS-Distribution")); 
    legend(hhNames); 
        
    % 1-Way Anova of Error Metric 
    %
    [p, anova_tbl, stats] = anova1(errorDist, hhNames, 'off');
    %{
    xticklabels(hhNames); 
    if p < P_VAL
        title(strcat("Significant Mean Error +/-", num2str((1-P_VAL)*100), "% CI")); 
    else
        title(strcat("Non-Significant Mean Error +/-", num2str((1-P_VAL)*100), "% CI")); 
    end
    ylabel(strcat("Cumulative ", FIELD_NAME));
    %}
    anova_cll{ff} = anova_tbl; 
    
    %}
    %f = gcf; 

    if SAVE_FIG
        plot_saveModule(f, SAVE_DIR, SAVE_FMT, strcat("BootStrapEDF-", FIELD_NAME)); 
        plot_saveModule(f2, SAVE_DIR, SAVE_FMT, strcat("BootStrapDist-", FIELD_NAME)); 
        
    end
   
    %figure; 
    %% Pair-wise Post-hoc comparisons
    % (Often redundant)

    [results, ~, ~, ~] = multcompare(stats,'Display', 'off', 'Alpha', P_VAL ); 
    %
    %ylabel(strcat("Cumulative ", FIELD_NAME)); 
    %yticklabels(hhNames); 

    multcomp_tbl = array2table(results, "VariableNames", ...
        {'Group','Control_Group','Lower_Limit','Difference','Upper_Limit','P_value'});    
    %
    multcomp_cll{ff} = multcomp_tbl; 
    %}
    
    if N_FIELDS == 1
        %// unwrap as a default
        anova_cll       = anova_cll{1};  
        multcomp_cll    = multcomp_cll{1}; 
    end
    
    if nargout == 0
        anova_cll = []; 
        multcomp_cll = []; 
    end
end

%{

%// Maximal distance of the errors; 
EMax = max([errorStruct(:).L_inf]); 

N_HH        = length(errorStruct); 
N_SPIKES    = length(errorStruct(1).x0States);  

%// we need to account for the number of unique tests
N_TESTS = trace(flipud(pascal((N_HH-1)))); 

BON_VAL = P_VAL/N_TESTS; %bonferroni correction factor for multiple comparisons. 

PLOT = 1; 

%HH_NAMES = errorStruct(:); 


%% Chi-Squares Test for significant differences ???

%% KS-Test ==> Test if distribution of errors are significantly different

KS_E1_CDF = zeros(EMax+1, N_HH); 
for hh = 1:N_HH
    KS_E1_CDF(:,hh) = cumsum(histcounts(errorStruct(hh).L1_running, 0:EMax+1))/N_SPIKES;
end

%// Find the maximal absolute differences between E1 Distributions
KSArr = zeros(N_HH); 
for hh = 1:N_HH
    for gg = 1:N_HH
        dx = KS_E1_CDF(:,hh) - KS_E1_CDF(:,gg); 
        KSArr(hh,gg) = max(abs(dx)); 
    end
end

ALPHA2 = 1- BON_VAL; 
%ALPHA2 = 1-(P_VAL-BON_VAL); 

sizeFactor  = sqrt(2*N_SPIKES/ N_SPIKES^2); %sqrt( [n+m]/[n*m]); 
cAlpha      = sqrt(-log(ALPHA2/2)/2); 

THRESH_VAL = cAlpha*sizeFactor; 

HH_SigArr = KSArr > THRESH_VAL; 

if PLOT == 1

figure;
for hh = 1:N_HH
    stairs(0:EMax,KS_E1_CDF(:,hh), 'lineWidth', 2); 
    hold on; 
end
title("Distribution of E1 Error Magnitude (KS-Test)"); 
ylabel("Cumulative P(E1)");
xlabel("E1 Magnitude"); 
legend({errorStruct(:).fieldname}); 
hold off; 
end

%% Permutation Test ==> Test if error rate distributions have significantly different means; 
% --> Need to use a 'paired permutation' test, as we are predicting from
% the same original values; hence errors 
%// Here we get the average overall E1 rate (average error distance), and
%its significance

spkError = reshape([errorStruct(:).L1_running], N_SPIKES, []); 

[sigGrtrMat, pvalMat] = mcompPermutePaired(spkError, ...
    'nShuffles',    N_SHUFFLES, ... 
    'pVal',         P_VAL, ... 
    'zScore',       Z_SCORE); 

CI_Vals = getCentralMomentCI(spkError, P_VAL, N_SHUFFLES, 'mean'); 

if 1 == 1; 
%if PLOT == 1
    figure; 
    mnVal = mean(spkError); 
    %stdVal = std(spkError); %// std-Dev doesn't really make sense, because data is not even in principle normally distributed. 
    bar(1:N_HH, mnVal); 
    ylabel("Mean E1 Error"); 
    xticklabels({errorStruct(:).fieldname}); 
    hold on
    errorbar(1:N_HH,mnVal, CI_Vals, 'LineStyle', 'none', 'color', 'k'); 
    %errorbar(1:N_HH,mnVal, diag(CIMat), 'LineStyle', 'none', 'color', 'k'); 
    title(strcat("Mean E1 Error +/-", num2str((1-P_VAL)*100), "% CI")); 
    1; 

end
%}

end