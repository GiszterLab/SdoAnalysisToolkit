%% pxTools_predictPxtFromPx0
% Core method for predicting and output distribution given an input
% distribution.
%
% Assume input distributions are columnwise
%
% Can pass two types of operators to this functions: Transition matrices
% (px) or difference matrices (dpx); If the later, select between two
% different types of predictions, if detected
%
% NOTE: Markov matrix cannot be raised to a non-integer power; if queried,
% will have to back-estimate SDO, and conform it, then evaluate it as 'L'
% 'given sdo, some ratio of prediction step, and px0, predict output
%
% Advancing L by a non-integer N_INTERVALS is equivalent to
% (L+1)^floor(N_INTERVALS) * (L*modulo(N_INTERVALS)+1); 
%
% NOTE: This framework doesn't currently support 'Z_DELAY' in probability
% distributions
%
% INPUTS: 
%   mat - Matrix used for prediction. May be a transition matrix, or a
%       differential SDO 
%   px0 - Observed probabilty distributions (passed as column vectors), to
%       predict output. 
%   N_INTERVALS - [Numeric]: Number of intervals to predict forward,
%       relative to the creation of the matrix (e.g. an SDO over 10 ms,
%       with a N_INTERVALS = 2 will predict event:event+20 ms). 
%       - If N_INTERVALS is not an integer, prediction will estimate L, and
%       use L for an arbitrary prediction interval. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [pxt] = pxTools_predictPxtfromPx0(mat, px0, N_INTERVALS)
if ~exist('N_INTERVALS', 'var')
    N_INTERVALS = 1; 
end

N_BINS = size(mat,1); 

WHOLE_INTERVALS = ismembertol(N_INTERVALS, round(N_INTERVALS)); 

%% Identify class of passed matrix

colSum = sum(mat,1); 

if all(all(mat > 0))
    matType = 'M';
elseif sum(colSum) > sqrt(N_BINS) %// arbitrary determination
    matType = 'M';
else 
    matType = 'L'; 
end

%% Conform M, if necessary

if ~WHOLE_INTERVALS && matType == 'M'
    disp("Warning: Estimating L from M"); 
    %mat = pxTools_getSdoFromJointArr(mat); 
    mat = mat-eye(N_BINS); 
    matType = 'L'; 
end 

switch matType
    case 'M'
        % transition/markov matrix;         
        scMat = mat^(N_INTERVALS); 
        nMat = normpdfcol2unity(scMat); 
        
    case 'L'
        % linear operator; L+1 = M; 
        %// All effects of dpx can be summed, then projected
        N_STEPS = floor(N_INTERVALS); 
        dt = N_INTERVALS - N_STEPS;  
        L = SAT.sdoUtils.conformsdo(mat);
        
        %
        L_STEPS = (L+eye(N_BINS))^N_STEPS; 
        Ldt = (L*dt+eye(N_BINS)); 
        %// convolve partials; 
        sumLdt = L_STEPS * Ldt; 
        nMat = normpdfcol2unity(sumLdt); 
        %
        %arr = expm(L*N_INTERVALS); 
        %nMat = normpdfcol2unity(arr); 
        
end

pxt = nMat*px0; 

end