%% dataAtPercentile
% Simple macro for establishing a cdf of the observed data, setting up
%the appropriate percentile search, and returning value which is at x% of
%the data amplitude

%// Data should be rectified prior to percentile search if absolute
%magnitude of percentile is sought

% Trevor S. Smith, 2022
%Drexel University college of medicine

function [dataPoint] = dataAtPercentile(xt, pct)

if pct > 1 
    pct = pct/100; 
end

xts = sort(xt); 

dataPoint = xts(max(round(length(xt)*pct),1)); 


1; 
end