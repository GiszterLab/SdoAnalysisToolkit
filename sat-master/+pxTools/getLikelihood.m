%% pxTools_getLikelihood
% // Distribution-wise metric for predicted/observed state distributions. 
% // Calculate the likelihood metric. 
% ASSUME: Input predicted and observed probability distributions are column
% vectors; equivalent sizes
%
% 

% --> We need to process the pdPx and obsPx to not have zeros in domain...
% else we need to ignore these when calculating... 

% --> Also... obsPx should be NON-filtered, in this instance, so we can estimate resolution of #points used;  

% --> The level of discretation could be an issue here... 

% --> Note that if the number of points used to generate the probability
% isn't provided, then the output likelihood will need to be scaled by
% 1^NPoints

function [lklhd] = pxTools_getLikelihood(pdPx, obsPx, varargin)
p = inputParser; 
defaultMod = 'log'; 
expectMod = {'log', 'linear'}; 
addOptional(p, 'modifier',  defaultMod, ...
    @(x) any(validatestring(x,expectMod)) ); 
addParameter(p, 'nPoints', 1); 
parse(p, varargin{:}); 
pR = p.Results; 

N_BIN_PTS   = pR.nPoints;  
MOD_TYPE    = pR.modifier; 

% --> What if we permit all zeros == 1 ?? 

[N_BINS, N_SPIKES] = size(pdPx); 

lklhd = zeros(1,N_SPIKES); 

% -- This isn't technically likelihood, because we should be using a
% discrete number of steps, but scales with it
pdx = pdPx.^(obsPx*N_BIN_PTS); 
%   --> Raise parameter probabilities by observed probability; This ideally
%   would be a whole-integer number ... 
pdx(pdx == 0) = 1; 

%pdx(isinf(pdx)) = 1; % need some way to deal with 0/0;

val = prod(pdx,1); 
%   --> Product across all elements; 

switch MOD_TYPE
    case 'log'
        lklhd = log(val); 
    case 'linear'
        lklhd = val; 
end

% || Post-Hoc check/correct
%
if any(isinf(lklhd)) 
    %warning(" -inf values in likelihood flushed to minimum real value"); 
    minRealVal = min(lklhd(~isinf(lklhd))); 
    lklhd(isinf(lklhd)) = minRealVal; 
end
%}
end