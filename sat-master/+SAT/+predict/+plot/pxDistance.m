%% Prediction Likelihood
% 
% Produces a violin plot of the supplied field of the errorStruct. Each
%value within the error field is treated as an observation, and the
%distribution of errors gives shape to the violin. The mean and median of
%the violin/distribution is co-plotted. 
%
%This script may be used for any field, but is utilized here to plot the
%KLD and likelihood metrics, measures of distribution-to-distribution
%similarity between a prediction and observation. 
%
% The KLD is the distance between two probability distributions, and hence
% a smaller value indicates a better fit between a hypothesis and
% observation. 
%
% Likelihood calculates the probability of an observation, given that the
% generative distribution is a set of parameters (hypothesis). A larger
% value indicates the model hypothesis is more likely to resemble the
% actual generative parameters, and hence is a better model fit.
%
% Given the large in values for different measures, median rather than mean
% is preferred as the best measure of central tendency. Significance is
% determined using a boostrapping procedure to generate 95% confidence
% intervals, and hence signifiance at a pVal of 0.05. 

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

function pxDistance(errorStruct, PXFIELD, varargin)
p = inputParser;
addOptional(p, 'N_DRAWS', 1000);
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
addParameter(p, 'plotProp',0); 
parse(p, varargin{:}); 
pR = p.Results; 

zScore = 2; 

SAVE_FIG        = pR.saveFig; 
SAVE_FMT        = pR.saveFormat; 
SAVE_DIR        = pR.outputDirectory; 
N_DRAWS         = pR.N_DRAWS; 

BOOTSTRAP = 1; 
if N_DRAWS == 0
    BOOTSTRAP = 0; 
end

if isstruct(pR.plotProp) 
    CUSTOM_PLOT = 1; 
    plotProp = pR.plotProp; 
else
    CUSTOM_PLOT = 0; 
    plotProp = []; 
end

[x0, XI]        = sort(errorStruct(1).x0States); 
N_SPIKES        = length(x0); 
sfields         = {errorStruct.fieldname};
N_FIELDS        = length(sfields); 
%%

sfields     = {errorStruct.fieldname};

metricArray = cellvcat({errorStruct.(PXFIELD)}'); 
% --> Cell --> Double; 
      
figure; 

if CUSTOM_PLOT
    cArr = zeros(3, N_FIELDS); 
    for ff = 1:N_FIELDS
        fName = sfields{ff}; 
        cArr(:,ff) = plotProp.(fName).color; 
    end
    violin( ...
        metricArray', ...
        'facecolor', cArr' ); 
else
%-- Violin plots; 
violin( ...
    metricArray');% ...
    %'xlabel', sfields ) ; 
end

if BOOTSTRAP
    hold on; 
    medianBootstrapArray = zeros(N_FIELDS, N_DRAWS); 
    LI = randi(N_SPIKES, N_DRAWS); %e.g. 1000x1000
    for  hh = 1:N_FIELDS
        datSamp     = metricArray(hh,LI); 
        datSamp2    = reshape(datSamp, N_DRAWS, []); 
        medianBootstrapArray(hh,:) = median(datSamp2,1); 
    end
    medianArray         = median(metricArray,2);  
    SEMBootstrapArray   = std(medianBootstrapArray,[],2); 
    %
    errorbar(medianArray, zScore*SEMBootstrapArray, 'LineStyle','none', 'color', 'k'); 
    hold off
    ylabel(strcat(PXFIELD, '\pm 95% C.I. S.E.M')); 
else
    ylabel(PXFIELD); 
end
xticklabels(sfields)

title(strcat(PXFIELD, " distribution; HH- Predicted x Observed Distributions")); 

%{

%// Calculate likelihoods
% --> Expand these observation (i.e. spikewise); 
for hh = 1:length(sfields)
    if ~isempty(x0)
        lkhd_x0.(sfields{hh}) = zeros(1,length(standardized_pdists.(sfields{hh}){muscle,unit})); %pregenerate empty;
        
        spd = standardized_pdists.(sfields{hh}){muscle,unit}; 
        
        mnn = min( spd(spd>0) ); 
        
        for spike=1:length(lkhd_x0.(sfields{hh}))
            % find the product of the observed states by the probability of
            % observing those states, given the predicted distribution; 
            
            lkhd_x0.(sfields{hh})(spike) = prod( standardized_pdists.(sfields{hh}){muscle,unit}(x0(:,spike),spike) ); 
        end  
    end
    lkhd_xt.(sfields{hh}) = zeros(1,length(standardized_pdists.(sfields{hh}){muscle,unit})); %pregenerate empty; 
    for spike=1:length(lkhd_xt.(sfields{hh}))
        %// Post-spike states;
            % look up the the predicted probabilty associated with each
            % observed state in the measured interval, then take the
            % product of each observation around spike to derive the
            % likelihood of that state-signal-sequence given the dist.
        lkhd_xt.(sfields{hh})(spike) = prod(standardized_pdists.(sfields{hh}){muscle,unit}(xt(:,spike),spike)); 
    end
    % --> Conform values of '0' to minimum non-zero val. (log(0) = -inf)
    if any(lkhd_x0.(sfields{hh}) <= 0)
        disp("flushing Likelihoods of zero to nearest non-zero val.");
        lkhd_x0.(sfields{hh})(lkhd_x0.(sfields{hh}) ==0) = min(lkhd_x0.(sfields{hh})(lkhd_x0.(sfields{hh}) > 0));
    end  
    if any(lkhd_xt.(sfields{hh}) <= 0)
        disp("flushing Likelihoods of zero to nearest non-zero val.");
        lkhd_xt.(sfields{hh})(lkhd_xt.(sfields{hh}) ==0) = min(lkhd_xt.(sfields{hh})(lkhd_xt.(sfields{hh}) > 0));
    end
end

%% Find the Confidence Intervals of the median likelihood 

%// Bootstrap Array = bsa; 
%// Standard Error Array = sea; 
numDraws = 1000; 
numSpikes = length(lkhd_xt.(sfields{hh})); 

for hh = 1:length(sfields)
    bsa_xt.(sfields{hh}) = zeros(numDraws,1); %prebuild
    if ~isempty(x0) %// extra lines here to avoid eval'ing multiple times
        bsa_x0.(sfields{hh}) = zeros(numDraws,1); %prebuild
        for draw = 1:numDraws
            bsa_xt.(sfields{hh})(draw) = log(median(datasample(lkhd_xt.(sfields{hh}), numSpikes, 'Replace', true))); 
            bsa_x0.(sfields{hh})(draw) = log(median(datasample(lkhd_x0.(sfields{hh}), numSpikes, 'Replace', true))); 
        end
        sea_xt.(sfields{hh}) = std(bsa_xt.(sfields{hh})); %1 std of bootstrap = standard error (of the median)
        sea_x0.(sfields{hh}) = std(bsa_x0.(sfields{hh})); %1 std of bootstrap = standard error (of the median)
    else
        for draw = 1:numDraws
            bsa_xt.(sfields{hh})(draw) = log(median(datasample(lkhd_xt.(sfields{hh}), numSpikes, 'Replace', true))); 
        end
        sea_xt.(sfields{hh}) = std(bsa_xt.(sfields{hh})); %1 std of bootstrap = standard error (of the median)
    end
        
end

%95% confidence interval = 2x SEA

se_xt = zeros(1,length(sfields)); 
se_x0 = zeros(size(se_xt)); 
for hh = 1:length(sfields)
    se_xt(1,hh) = sea_xt.(sfields{hh}); 
    se_x0(1,hh) = sea_x0.(sfields{hh}); 
end

%% Plot Log-Likelihood + Confidence Intervals 
sum_arr_x0 = zeros(1,length(sfields)); 
sum_arr_xt = zeros(1,length(sfields)); 

%single matrix for boxplot
log_lkhd_arr = zeros(length(lkhd_xt.(sfields{1})), length(sfields)); 


for hh=1:length(sfields)
    sum_arr_x0(hh) = log(median(lkhd_x0.(sfields{hh}))); 
    sum_arr_xt(hh) = log(median(lkhd_xt.(sfields{hh}))); 
    log_lkhd_arr(:,hh) = real(log(lkhd_xt.(sfields{hh})));
    %// real added because of occassional imaginary component (0i) from log
end

% --- Violin plot 
figure; 
violin(log_lkhd_arr, 'facecolor', [0 0.4470 0.7410], 'medc', 'b');
%// Using default blue for plotting; 
xticklabels(sfields)
ylabel("Log-Likelihood")
errorbar(1:length(sfields),sum_arr_xt,2*se_xt, 'LineStyle','none', 'color', 'r', 'CapSize', 24);
title("X(t) Log-Likelihood Distributions (w/ 95% CI)"); 
% -- Bar chart

figure; 

subplot(1,2,1); 
bar(1:length(sfields), sum_arr_x0); 
hold on
title("X0 Median Log-Likelhood (w/ 95% CI)"); 
ylabel("Median Log-Likelihood")
xticks(1:length(sfields)); 
xticklabels(sfields); 
errorbar(1:length(sfields),sum_arr_x0,2*se_x0, 'LineStyle','none', 'color', 'k');
hold off


subplot(1,2,2); 
bar(1:length(sfields), sum_arr_xt); 
hold on
title("Xt Median Log-Likelihood (w/ 95% CI)"); 
ylabel("Median Log-Likelihood")
xticks(1:length(sfields)); 
xticklabels(sfields); 
errorbar(1:length(sfields),sum_arr_xt,2*se_xt, 'LineStyle','none', 'color', 'k');   
hold off
    %}

%% Plotter Save Module
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, strcat(PXFIELD, '-Distributions_violin'), [0,0,800,800]); 
end

end