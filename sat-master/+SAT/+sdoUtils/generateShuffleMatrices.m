%% generateShuffleMatrix; 
%
% Using a mean and standard deviation matrices, generate a mixture of
% normally distributed scalars for shuffles. 
% 
% Used to simulate draws from the predefined Mean + Standard Deviation

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

function [shuffleMat] = generateShuffleMatrices(meanMat, stdMat, nShuffles, varargin)
normConformType = 'none'; 
expectConformType = {'none', 'L', 'M'}; 
p = inputParser; 
addParameter(p, 'conform', normConformType, ... 
    @(x) any(validatestring(x, expectConformType)) ); 
parse(p, varargin{:}); 
pR = p.Results; 

nStates = size(meanMat,1); 

sclMat = randn(nStates, nStates, nShuffles); 

shuffleMat = zeros(nStates,nStates,nShuffles); 

for z = 1:nShuffles
    shuffleMat(:,:,z) = meanMat+sclMat(:,:,z)*stdMat; 
    switch pR.conform
        case 'L'
            shuffleMat(:,:,z) = SAT.sdoUtils.conformsdo(shuffleMat(:,:,z)); 
        case 'M'
            shuffleMat(:,:,z) = shuffleMat(:,:,z)./sum(shuffleMat(:,:,z), "all"); 
    end
end


end