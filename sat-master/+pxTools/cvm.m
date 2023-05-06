%% Cramer-Von Mises
% Here, we measure the 'goodness of fit' between an EDF (observed) and
% model(s) pdf to give as a proxy for likelihood of observation of a
% probability distribution as a fundamental object (i.e. we are measuring
% the probability of observing a -distribution- rather than the probability
% of observing state -within- (an interval, given) a distribution. 
%
% W^2 = integral ( [F(x) - G(x)]^2 dx) (continous form)
% Here; sum( F(x)- G(x)).^2 / (N_DX-1) = DOF; 
%
% INPUT
% - px_edf [N_STATES x N_OBS] doubles array of (observed) probability
%       distributions
% - px_model [N_STATES x N_OBS] array OR {1 x N_HH} of arrays, containing
%       the modeled distributions; 
% OUTPUT
%   - dist : [1 x N_OBS] or {1 x N_HH} of arrays, containing the
%   observation-wise CVM between distributions. 

% Trevor S. Smith, 2023
% Drexel University College of Medicine

function [dist] = cvm( px_edf, px_model, SMOOTH_REF, SMOOTH_HH)
if ~exist('SMOOTH_REF', 'var')
    SMOOTH_REF = 0; 
end

if ~exist('SMOOTH_HH', 'var')
    SMOOTH_HH = 0; 
end

%SMOOTH = 1; 

if isa(px_model, 'double')
    % .. convert to cell
    ISCELL = 0; 
    px_model = {px_model}; 
    N_HH = 1; 
else
    ISCELL = 1; 
    N_HH = length(px_model); 
end

[N_STATES, ~] = size(px_edf); 

%% First, we can *optionally* test if all potential states are p(xi)>0; and smooth

if SMOOTH_REF
    gk =  pxTools.getH0Array(N_STATES, 1, 1, 'normalize', 1); 
    px_edf = gk*px_edf; 
end

if SMOOTH_HH
    for hh = 1:N_HH
        px_model{hh} = gk*px_model{hh}; 
    end
end

%% Then, convert all models to cdfs

edf_cdf = cumsum(px_edf); 
%%
% 
model_cdf = cell(1,N_HH);  
for hh = 1:N_HH
    model_cdf{hh} = cumsum(px_model{hh}); 
end

%% Take Sum-of-squared differences
% Approximation of the integrated differences of two continuous CDFs/PDFs
% (von Mises)

if ~SMOOTH_REF
    %// temporarily increase DOF to avoid likelihood = 0; 
    N_STATES = N_STATES+1; 
end

dist = cell(1,N_HH); 
for hh = 1:N_HH
    dist{hh} = sum((edf_cdf - model_cdf{hh}).^2)/ (N_STATES-1); 
end

% -- Unwrap to match input format
if ~ISCELL 
    dist = dist{1}; 
end

end