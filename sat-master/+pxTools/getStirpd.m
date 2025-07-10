%% pxTools.getStirpd
% using columnwise observations of state, generate the Spike-triggered
% impulse response probability distribution (STIRPD)
%
% for faster/modular generation
%
% INPUTS: 
%   [x0_vals] = [k,n] array of INTEGER state values [prespike]
%   [x1_vals] = [k,m] array of INTEGER state values [postspike]
%           - if left [], will plot only one half; 
%   max_x     = (1) [Numeric]: Max value of state to query/plot; 
% OUTPUTS: 
%   stirpd  = [k,n+m] array of positional p(x,t). 


% Trevor S. Smith, 2025

function stirpd = getStirpd(x0_vals, x1_vals, max_x)

t0 = size(x0_vals,1); 
t1 = size(x1_vals,1); 

xV = [x0_vals; x1_vals]; 

nt = t0+t1; 

stirpd = zeros(max_x,nt); 

for t = 1:nt
    px = histcounts(xV(t,:), (1:max_x+1)-0.5, 'Normalization','probability'); 
    stirpd(:,t) = px; 
end


end