%% getCommonCdfPlot
% Common plotter module used in MAB's code to plot significance of 
% test statistic vs. distribution of shuffled test statistics. For use
% within the SDO Analysis Toolkit.

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

function getCommonCdfPlot(shuffStat, testStat, SIG_PVAL)

if ~exist('SIG_PVAL', 'var')
    SIG_PVAL = 0.05; 
end
if isempty(SIG_PVAL)
    SIG_PVAL = 0; 
end
if SIG_PVAL > 1
    %// everything is sig. 
    prob = 0; 
elseif SIG_PVAL < 0
    %// nothing is sig. 
    prob = 1; 
else
    %// pVal is logical ; 
    prob = (1-SIG_PVAL); 
end

[CDF, X] = ecdf(shuffStat); 

Ind = find(X>=testStat,1); %Indexed position of the test stat vs. shuff dist

if ~isempty(Ind)
    TestPVal=1-CDF(max(Ind-1,1)); 
else
    TestPVal = 1; 
end

Xi = dataAtPercentile(X, prob); 

if (TestPVal <= SIG_PVAL) || (testStat >= X(end))
    sigString = '';
else
   sigString = 'Not  ';
end

%_________PLOT CDF_________

plot(X,CDF, 'lineWidth', 2),
hold on,

line( [Xi Xi], [0,1], 'lineStyle', '--', 'color', [0.8500 0.3250 0.0980]); 
text(Xi,SIG_PVAL,[num2str(prob*100) '% sig. threshold']),
line( [testStat, testStat], [0,1], 'lineWidth', 2, 'color', 'g'); 

leg2={'Shuffle CDF','Significance Threshold', 'Observed value'};
legend(leg2)

xlabel('Total Deviation from baseline, over all states')
ylabel('CDF(null distance of shuffles)')
title({'SDO at Spike ';   strcat(sigString, ' Significant, pVal=', num2str(SIG_PVAL))});

end