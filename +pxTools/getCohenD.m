%% Cohen's D Effect Size; Tabular Display; 
% Use for multi-comp HH testing, evaluate effect sizes; 
% 
% Display a UI figure here for ease of interpretation, rather than save to
% var-space. (Expectation: We will first have screened for significance, so
% this is just a measure of the differences in the means of the error
% stats)
%
% Calculate the Pairwise Cohen's effect size as mean(x1)-mean(x2)/
% std(x1,x2); 
%
%
% INPUTS: 
%   observedData = [N_OBSERVATIONS x N_HYPOTHESES] doubles data structure; . 
%   PLOT    = [0/1] whether to display as a UI-table (Default = 0)
% OUTPUTS
%   compArr = [N_HH x N_HH] Array containing the comparison-wise Cohen-D
%       from A-->B at compArr(A,B); (i.e. if D < 0; B < A )

% NOTE: UI-Tables have limited display options. It is preferable not to
% generate displays in a for-loop, as they are relative unannotated. 

% Trevor S. Smith, 2023
% Drexel University College of Medicine

function [compArr] = getCohenD(observedData, PLOT, varNames)
if ~exist('PLOT', 'var')
    PLOT = 0; 
end
GEN_NAMES = 0; 
if ~exist('varNames', 'var')
    GEN_NAMES = 1; 
end

[N_OBS, N_HH] = size(observedData); 

compArr = zeros(N_HH); 

hMean = mean(observedData); 
hVar  = var(observedData); 

% Measure distance A--> B for (A,B); 

for h1 = 1:N_HH
    for h2 = 1:N_HH 
        h12Std = sqrt( (hVar(h1)+hVar(h2))/2);  
        compArr(h1,h2) = (hMean(h1)-hMean(h2))/h12Std; 
    end
end

% ++ Format at tabular data for uiTable ++; 
if PLOT
    %// Generate Names; 
    if GEN_NAMES
        nmArr = cell(N_HH,1); 
        for hh = 1:N_HH
            nmArr{hh} = strcat('HH', num2str(hh)); 
        end
    else
        nmArr = varNames; 
    end
    tData = array2table(compArr, 'rowNames', nmArr, 'VariableNames',nmArr); 
    fig = uifigure("Position", [500 500 600 500]); 
    uitable(fig, ...
        "Data", tData, ...
        'Position', [0 -100 600 600]); 
    uicontrol('Style', 'text', 'Position', [0 80 600 600], 'String', 'My Example Title');
end


if nargout == 0; 
    compArr = []; 
end

end


