%% bootstrapz
%
% A wrapped implementation of the boostrapping function implemented for 3D
% arrays. 
%
% Includes the option for iterative bootstrapping + post-hoc tests to
% ensure test statistic is normally distributed (else, increase global number
% of bootstraps). 
%
% INPUTS
%   mat3 - a 3D array. The final element (z) is considered the test
%       dimension to independently boostrap over, for every row and column 
%       of size 1, size 2
%   bootfun - A function handle of operation to apply to boostrap. 
%       Default = @mean 
%   multiplier - Integer. Number of boostraps (if not iterative), or
%       scanning multiplier for iterations. 
%       Default = 1000; 
% NAME-VALUE PAIRS
%   'iterative'  -[0/1] Whether to iteratively increase #bootstraps if not
%       all shuffled elements are normally distributed, or 0. 
%       Default = 0
%   'maxComps'   - Numeric. Maximum cutoff for scanning iterator to prevent
%           infinite 'while' loops; 
%       Default = 10000
%  OUTPUTS: 
%   bootstat    - A 3D array of shape [size(1), size(2), numBootstraps]
%   H           - Results of (final) t-test for normal distributions, on an
%       elementwise basis 

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

function [bootstat, H] = bootstrapz(mat3, bootfunc, multiplier, vars)
arguments
    mat3
    bootfunc function_handle = @mean; 
    multiplier = 1000; 
    vars.passNormal = 0; %whether to simply pass if normal
    vars.iterative {mustBeNumericOrLogical} = 0; 
    vars.maxComps = 10000; 
end
ii = 1; 

if ~ vars.iterative
    vars.maxComps = multiplier; 
end

[sz_1, sz_2, sz_3] = size(mat3); 

% flatten into columnwise observations; 
mat2 = reshape(permute(mat3, [3,1,2]), sz_3, [], 1);

if vars.passNormal
    % Avoid unnecessary boostrapping
    % __ Initialize; 
    H0 = ttest(mat2-mean(mat2)); 
    H0(isnan(H0)) = 0;
    H1 = ~all(mat2==0); 
    HH = H0 & H1; 
    btstrp_x = bootfunc(mat2); 
    nBootstraps = 1; 
else
    % // maybe through the initial test here to avoid initial boostrap
    HH = true(sz_1*sz_2, 1); 
end


% __ ensure convergence
while any(HH)
    nBootstraps = ii*multiplier; 
    btstrp_x = bootstrp(nBootstraps, bootfunc, mat2); 
    % __ posthocs; 
    % || Pairwise t-test for normal distributions; 
    H0 = ttest(btstrp_x - mean(btstrp_x));
    H0(isnan(H0)) = 0; %post-hoc convert non-sampled to 0; 
    H1 = ~all(btstrp_x == 0); % test for unsampled data combos; 
    
    HH = H0 & H1; % Non-normal distributions populated w/ non-zero values
    %___________
    ii = ii+1; 
    if nBootstraps >= vars.maxComps
        break
    end
end

%// convert back to original 3D arr shape; 
bootstat = permute(reshape(btstrp_x, nBootstraps, sz_1, sz_2), [2,3,1]);

if nargout == 2
    H = reshape(HH, sz_1, sz_2); 
else
    H = []; 
end

end