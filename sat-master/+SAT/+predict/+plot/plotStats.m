%%

% Extracted from 'testSig' to better segregate the predictions; May be
% redundant 

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

function plotStats(obj )


% __ Let's just plot a simple bar chart of the population error rate; 


% __ > per test
sFields = obj.error_fields; 

nFields = length(sFields); 

nCols = ceil(sqrt(nFields)); 
nRows = ceil(nFields/nCols); 

figure; 
tiledlayout(nCols, nRows); 
%
for f = 1:length(sFields)
    nexttile; 
    % __ Bootstrapped Mean - Best Estimate of actual Error rate
    x = obj.errorSig_HH{1, f}.bootstrap_mean; 
    % __ Bootstrapped  95% CI - Range Estimate for Actual Error rate 
    x_off = obj.errorSig_HH{1,f}.confidenceInterval - x; 
    %
    bar(x); 
    hold on; 
    errorbar(x,x_off, 'LineStyle','none', 'Color', 'k'); 
    title(sFields{f}); 

end

%{
figure; 
tiledlayout(nCols, nRows); 
for f = 1:length(sFields) 
    nexttile; 
end
%}

1; 


end