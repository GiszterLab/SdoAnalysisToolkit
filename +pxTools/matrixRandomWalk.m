%% pxTools_matrixRandomWalk()
%
% Simulate a specified number of transtions, given an input transition
% matrix (e.g. Markov), under the assumption of a random-walk
%
% Generate N_STEPS transitions for N_SIM sets of data; 
%
% NOTE: 'Steps' will be given at the resolution of the transition matrix
% (e.g. a markov created from 1ms observations will give steps at 1 ms, but
% an SDO w/ 10 ms steps will give a step over 10 ms. In this later case,
% the random walk value can be thought of as the chance mean of the
% distribution the 'step' represents
%
% INPUT:
%   mat - transition matrix to simulate 
%   N_STEPS - Total number of steps to use (number of transitions +1)
%   N_SIM   - Number of simulations of N_STEPS to perform
%   OPTIONAL NAME-VALUE PAIRS
%       'startVal'  - [integer] - Starting state for step 1. 
%

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [randWalkMat] = matrixRandomWalk(mat, N_STEPS, N_SIM, varargin) 

NBINS = size(mat,1);

p = inputParser; 
addOptional(p, 'startVal', 'None'); 
parse(p, varargin{:}); 
pR = p.Results; 

SEED = pR.startVal; 

seedMap = zeros(NBINS,1);
x0Class = class(SEED); 
switch x0Class
    case {'string', 'char'}
        cnvrt = str2double(SEED);
        if isnan(cnvrt)
        %if isempty(cnvrt) 
            %// assume empty reference; randomly assign
            %seedMap = (0:NBINS-1)/NBINS;
            seedMap = 1:NBINS/NBINS; 
        else
            %// assume single state; 
            seedMap(cnvrt:end) = 1;
        end
    case 'double'
        if length(SEED) == 1
            %// assume single state; 
            seedMap(SEED:end) = 1;
        else
            %// assume input = distribution; 
            seedMap = cumsum(SEED); 
        end
end

%// norm to 1, if not already
mat = mat./repmat(sum(mat,1),NBINS,1); 

matCDF = cumsum(mat, 1); 

randWalkMat = zeros(N_SIM, N_STEPS); 

%//perform all random draws at once; itterate over state assignment
randVals = rand(N_SIM, N_STEPS); 
randSeed = rand(N_SIM,1); 

%// assign seeds
seedVals = ones(N_SIM,1);
for ss = 1:N_SIM
    seedVals(ss) = find(seedMap >= randSeed(ss),1); 
end

randWalkMat(:,1) = seedVals; 

%// assign simulated state
for ss = 1:N_SIM 
    xp = randWalkMat(ss,1);
    for pp = 2:N_STEPS 
        rp = randVals(ss,pp); 
        xp = find(matCDF(:,xp) >= rp,1);  
        randWalkMat(ss,pp) = xp; 
    end

end

end

