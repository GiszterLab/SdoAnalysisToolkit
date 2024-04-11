%
% Used to calculate the sum-squared error between each shuffle and the mean
% of the shuffles, vs. the spike-triggered unit and the mean of the
% shuffles. Signfificance is provided as the relative magnitude of the test
% statistic vs. the PVal
%

% Copyright (C) 2023 Trevor S. Smith
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

function [isSig, ssqrd, stat]=sigSSquaredCalculator(shuff,unit,SIG_PVAL, Z_TRANSFORM)
if ~exist('Z_TRANSFORM', 'var')
    Z_TRANSFORM = 0; 
end

isSig=0;
%pVal=normcdf(zScore);
%//if the dim of shuff is greater than 2-D this means it s 1 x nbins x
%numShuffles:
% We want to get random shuffles

[X_DIM, Y_DIM, Z_DIM] = size(shuff); 

N_POP_DIM = (X_DIM>1)+(Y_DIM>1); 


if isempty(shuff)
    %// allow plot even if N_SHUFF = 0
    shuff = zeros(size(unit)); 
end

meanShuff = mean(shuff,3); 

if Z_TRANSFORM
    % // Z-Transform
    % z = x-u/s; 
    meanShuffZ = repmat(meanShuff, 1,1, Z_DIM); 
    stdShuff = std(shuff,[],3); 
    %// Need to compensate for unobserved for denominator
    stdShuff(stdShuff == 0) = 1; 
    
    stdShuffZ = repmat(stdShuff,1,1,Z_DIM); 
    
    zShuff = (shuff-meanShuffZ)./stdShuffZ; 
    %
    %Unit Norm
    zUnit = (unit - meanShuff)./stdShuff; 
    
    %// OVERWRITE
    
    unit = zUnit; 
    shuff = zShuff; 
    
end

%//compute the distance of actual increase-decrease-rate-diffs from its
%means in the null hypothesis (shuffled spikes); This is our statistic
%(Sum of Squared Errors; SSE)
stat=sum((unit-meanShuff).^2);

%% compute the distribution of our statistic stat Here

meanArr = repmat(meanShuff, 1,1,Z_DIM); 

ssqrd = squeeze( sum( (shuff-meanArr).^2) ); 

if N_POP_DIM == 2
    %// sum over remaining dimension
    stat = sum(stat);
    ssqrd = sum(ssqrd); 
end

%ssqrd=sum((bsxfun(@plus,shuff,-meanshuff)).^2,2);

[CDF, X]=ecdf(ssqrd(:)); % cumulative dist
% see if the stat is above the threshold set by pValue pVal
prob = 1-SIG_PVAL;
[CDFi, XInd] = min(abs(CDF-prob));
Xi=X(XInd);
if stat>=Xi
    isSig=1; % it is significant
end

% // 

if nargout == 1; 
    ssqrd   = []; 
    stat    = []; 
end
    

end