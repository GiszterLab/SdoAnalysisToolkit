%%
% Redux of the function meant to be used with the 'predictError' class
% generated by the 'sdoMat' and 'sdoMultiMat' classes

% This is the first attempt to separate hypothesis generation from the
% plotting of the significance

% TODO: Add a simple 'isSig' or something. 

%testSig(se.errorStruct, se.error_fields, se.error_fields_x_state); 
%testSig(se.errorStruct, {}, se.error_fields_x_state); 

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

function [populationStats, xWiseStats] = testSig2(errorStruct, scalarFields, scalarFields_xWise, vars)
arguments
    errorStruct
    scalarFields 
    scalarFields_xWise = {}; 
    vars.nShuffles = 1000; 
    vars.null = []; 
    vars.alpha = 0.05; 
end

%______
% Find bounds for estimating confidence intervals 
lo_thresh = vars.alpha/2; 
hi_thresh = 1-vars.alpha/2; 
critVal = tinv([lo_thresh, hi_thresh], vars.nShuffles-1); 

sNames = [scalarFields, scalarFields_xWise];

%_____
n_sFields = length(sNames); 
n_hh = length(errorStruct); %number of hypotheses
%_____

maxComps = 5000; 

statsCell = cell(1, n_sFields); 

for s = 1:n_sFields %For each test
    cellDat = {errorStruct(:).(sNames{s})}; 
    xData = cellvcat(cellDat'); 
    %
    SKIP_MULTICOMP = 0; 
    % ___
    if isa(xData, 'cell')
        % For x0-wise data; 
        GROUPWISE = 1; 

        nEvents = length(errorStruct(1).x0States); 
        nStates = length(errorStruct(1).(sNames{s})); 
        groupArr = zeros(nEvents,1); 
        x0 = 1; 
        cLen = cellfun(@length, xData(1,:)); 
        for xx = 1:nStates  
            x1 = x0+cLen(xx)-1; 
            groupArr(x0:x1) = xx; 
            x0 = x1+1; 
        end

        groupArr = repmat(groupArr, 1, n_hh); 

        catData = cellvcat(cellhcat(xData))'; 

        if nchoosek(nStates,2) < maxComps
            % // avoid blowing up 
            SKIP_MULTICOMP = 1; 
        end

    else
        GROUPWISE = 0; 
    end


    S = getStatsStruct(); 
    S.errorMetric = sNames{s}; 
    S.alpha = vars.alpha; 

    % ___ Determine population-level effects 
    % kruskal wallis doesn't require equal variance; which is usually the
    % case for our bootstrapped distributions

    if GROUPWISE
        p       = zeros(1,n_hh); 
        tbl     = cell(1,n_hh); 
        stats   = cell(1,n_hh); 
        mc      = cell(1,n_hh); 
        for h = 1:n_hh
            %// Internal error rate by hypothesis; 
            [p_h,tbl_h,stats_h] = kruskalwallis(catData(:,h), groupArr(:,1), 'off');
            p(h) = p_h; 
            tbl{h} = tbl_h; 
            stats{h} = stats_h; 
            %
            if ~SKIP_MULTICOMP
                str = evalc('multcompare(stats_h, "CriticalValueType","bonferroni")');
                mc{h} = ans; %capture from intrinsic;
            end
        end
    else
        [p,tbl,stats] = kruskalwallis(xData',[],'off'); 
        str = evalc('multcompare(stats, "CriticalValueType","bonferroni")');
        mc = ans; %capture from intrinsic;
        
    end
    S.kruskalWallis_pval = p; 
    S.kruskalWallis_tbl  = tbl; 
    S.kruskalWallis_stats= stats; 

    % // Note this has 'baked in' p-value Correction; 
    %// wrapped in evalc to suppress dialog
    S.multicompare_tbl = mc; 

    % __ Parse pairwise into a logical array;  

    if GROUPWISE
        HxH = cell(1, n_hh); 
        if ~SKIP_MULTICOMP
            for h = 1:n_hh
                HxH{h} = false(nStates); 
                for ii = 1:length(mc{h})
                    h1 = mc{h}(ii,1); 
                    h2 = mc{h}(ii,2); 
                    HxH{h}(h1,h2) = mc{h}(ii,6) < vars.alpha; 
                end
            end
        end
    else
        HxH = false(n_hh); 
        for ii = 1:length(mc)
            h1 = mc(ii,1); 
            h2 = mc(ii,2); 
            %// Note this already has corrections; 
            HxH(h1,h2) = mc(ii,6) < vars.alpha; 
        end
    end
        
    S.HxH_multicomp = HxH; 

    % __ This is the distribution of the expected cumulative error ___ 
    if GROUPWISE
        shuffSum_xWise = cell(n_hh,nStates); 
        x_bar = cell(1,n_hh); 
        x_std = cell(1,n_hh); 
        CI = cell(1,n_hh); 
        chD = cell(1,n_hh); 
        for h = 1:n_hh
            shuff_mean  = zeros(1, nStates); 
            shuff_std   = zeros(1, nStates);  
            shuff_ci    = zeros(2, nStates); 
            for xx = 1:nStates
                if isempty(xData{h,xx})
                    shuffSum_xWise{h,xx} = zeros(vars.nShuffles,1); 
                    continue; 
                end
                if length(xData{h,xx}) == 1
                    shuffSum_xWise{h,xx} = xData{h,xx}*ones(vars.nShuffles,1); 
                else
                    shuffSum_xWise{h,xx} = bootstrp(vars.nShuffles, @sum, xData{h,xx});
                end
                %___________
                shuff_mean(xx) = mean(shuffSum_xWise{h,xx}); 
                shuff_std(xx)  = std(shuffSum_xWise{h,xx}); 
                se = shuff_std(xx)/sqrt(vars.nShuffles); 
                %
                shuff_ci(:,xx) = [shuff_mean(xx) + critVal(1)*se; shuff_mean(xx) + critVal(2)*se]; 
                %
            end
            x_bar{h} = shuff_mean; 
            x_std{h} = shuff_std; 
            CI{h}    = shuff_ci; 
            chD{h}   = pxTools.getCohenD(cellhcat(shuffSum_xWise(h,:))); 
        end
    else
        shuffSum = bootstrp(vars.nShuffles, @sum, xData'); 
        % ___ >> This should be effectively normally distributed now; 
        x_bar = mean(shuffSum); 
        x_std = std(shuffSum); 
        se = x_std/sqrt(vars.nShuffles); 
        CI = [x_bar + critVal(1)*se; x_bar + critVal(2)*se]; 
        %
        % __ Get the overall effect size; 
        chD = pxTools.getCohenD(shuffSum); 
    end

    S.bootstrap_mean = x_bar; 
    S.bootstrap_std = x_std; 

    % __ This is the range of values for which a difference in the means is
    % effectively due only to potential chance

    S.confidenceInterval = CI; 

  
    S.cohensD = chD; 
    %
   statsCell{s} = S; 
end

% ___ Reverse Parse by type; 

nPopStats   = length(scalarFields); 
nXwiseStats = length(scalarFields_xWise); 

populationStats = statsCell(1:nPopStats); 
xWiseStats = statsCell(nPopStats+1:end); 

end


function S = getStatsStruct()
S = struct( ...
    'errorMetric',      '', ...
    'alpha',             0.05, ...
    'kruskalWallis_pval', cell(1,1), ...
    'kruskalWallis_tbl', cell(1,1), ...
    'kruskalWallis_stats', cell(1,1), ...
    'multicompare_tbl',   cell(1,1), ...
    'HxH_multicomp',        0, ...
    'bootstrap_mean',       0, ...
    'bootstrap_std',      0, ...
    'confidenceInterval', [0;0], ...
    'cohensD',          0); 


end