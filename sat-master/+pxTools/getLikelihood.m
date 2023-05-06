%% pxTools_getLikelihood
%  Distribution-wise metric for predicted/observed state distributions. 
% Calculate the likelihood metric. (L(H|x) = p(x|H); 
% --> We assume each distribution is independent
% ASSUME: Input predicted and observed probability distributions are column
% vectors; equivalent sizes
%
% 'nPoints' should be the number of (time) points which went into
% generating the distribution, rather than the distribution proper. 

% When acting as a distribution, use the Cramer-Von Mises metric as a value
% proportional to the probablity of drawing an observed distribution from
% an EDF given 'infinite' draws. 

% --> Also... obsPx should be NON-filtered, in this instance, so we can estimate resolution of #points used;  

% --> The level of discretation could be an issue here... 

% --> Note that if the number of points used to generate the probability
% isn't provided, then the output likelihood will need to be scaled by
% 1^NPoints

function [lklhd] = getLikelihood(pdPx, obsPx, varargin)
p = inputParser; 
defaultMod = 'log'; 
expectMod = {'log', 'linear'};
%
defaultMethod = 'continuous'; 
expectMethod = {'continous', 'discrete'}; 
%
addOptional(p, 'modifier',  defaultMod, ...
    @(x) any(validatestring(x,expectMod)) ); 
addParameter(p, 'method', defaultMethod, ... 
    @(x) any(validatestring(x, expectMethod)) ); 

addParameter(p, 'nPoints', 1); 
parse(p, varargin{:}); 
pR = p.Results; 

METHOD      = pR.method; 
N_BIN_PTS   = pR.nPoints;  
MOD_TYPE    = pR.modifier; 

% ___ Upgrade to permit multi-comp
if isa(pdPx, 'cell')
    ISCELL = 1;
    N_HH = length(pdPx); 
else
    ISCELL = 0; 
    N_HH = 1; 
    pdPx = {pdPx}; %Temporary Wrap
end
% ____ 

% --> What if we permit all zeros == 1 ?? 

%[N_BINS, N_SPIKES] = size(pdPx{1}); 

lklhd = cell(1,N_HH); 
val = cell(1, N_HH); 

switch METHOD
    case 'discrete'
        % // These are independent events WITHIN a sampled distribution; 
        % -- This isn't technically likelihood, because we should be using a
        % discrete number of steps, but scales with it
        for hh = 1:N_HH
            pdx = pdPx.^(obsPx*N_BIN_PTS); 
        %   --> Raise parameter probabilities by observed probability; This ideally
        %   would be a whole-integer number ... 
            pdx(pdx == 0) = 1; 
            val{hh} = prod(pdx,1); 
        end

    case 'continuous'
        % empirical distributions should be treated as observations from a
        % continuous distribution --> we need to treat px as a fundamental
        % object. perform integral (f(x).*g(x)) to measure between pd; 
        %
        % --> We can take the sum-squared differences of CDF (Cramer von
        % Mises Metric)
        %cvm_val = pxTools.cvm(obsPx, pdPx);
        cvm_val = pxTools.cvm(obsPx, pdPx, 1); %use Smoothed values to ensure overlap 
        
        % - Here we assume the L(HH|x) = p(x|HH); and p(x|HH) = 1- cvm; 
        for hh = 1:N_HH
            % --> This value should scale w/ likelihood of observing a
            % distribution, given an (estimated) distribution. 
            val{hh} = 1-cvm_val{hh}; 
        end
        % --> Maximum upperbound on cmv is (DOF-1)
end

%% Apply Modifications/ Conformation

for hh = 1:N_HH
    switch MOD_TYPE
        case 'log'
            lklhd_val = log(val{hh}); 
        case 'linear'
            lklhd_val = val{hh}; 
    end
    
    % || Post-Hoc check/correct
    %pdx(isinf(pdx)) = 1; % need some way to deal with 0/0;
    %   --> Product across all elements; 
    if any(isinf(lklhd_val)) 
        %warning(" -inf values in likelihood flushed to minimum real value"); 
        minRealVal = min(lklhd_val(~isinf(lklhd_val))); 
        lklhd_val(isinf(lklhd_val)) = minRealVal; 
    end
    
    lklhd{hh} = lklhd_val; 
end

if ~ISCELL
    %// unwrap
    lklhd = lklhd{1}; 
end

%}
end