%% Gaussian Kernel 
%// grab a generic gaussian kernel for 1D filtering of discrete-sampled
% points
%
% INPUTS
%   WID (Integer) - Number of states/positions adjacent to mean to estimate
%       the kernel over
%   STD (Integer) - The standard deviation of the gaussian
% OUTPUT
%   kn - Kernel for filtering, sum normalized to 1. 

% Adapted from code from MAB
% Written by Trevor Smith, 2022
% Drexel University College of Medicine

function [kn] = getgausskernel(WID, STD)
if ~exist('WID', 'var')
    WID = 1; 
end
if ~exist('STD', 'var')
    STD = 1; 
end

fcoeff=exp(-(-WID:WID).^2/(2*STD^2));
kn=fcoeff/sum(fcoeff);

end
