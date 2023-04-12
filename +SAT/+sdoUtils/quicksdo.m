%% quicksdo
%
% A function to quickly get the SDO matrix (and covariance matrix) from a
% prespike and postspike distribution, without the full SDO script. This is
% often not ideal. 
%
% Uses the V3 algorithm. 
%
% INPUTS: 
%   px0: A [nStates x nSpikes] doubles array of prespike state distributions; 
%   px1: A [nStates x nSpikes] doubles array of postspike state
%       distributions
% OUTPUTS; 
%   sdoMat: A [nStates x nStates] matrix corresponding to the SDO
%   covMat: A [nStates x nStates] matrix corresponding to the background
%       covariance matrix of px0--> px1. 

function [sdoMat, covMat] = quicksdo(px0, px1)

%// Assume that px0 and px1 are provided as [N_STATES x N_OBSERVATIONS]
%arrays. 

px0_arr = normpdfcol2unity(px0); 
px1_arr = normpdfcol2unity(px1); 

[~, N_SPIKES] = size(px0); 

sdoMat = (px1_arr*px0_arr') - diag(sum(px0_arr,2))/ N_SPIKES; 
covMat = (px1_arr*px0_arr') / N_SPIKES; 

if nargout == 1
    covMat = []; 
end
end