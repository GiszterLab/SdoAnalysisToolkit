%% zscore_inv
% Inverse a Z-score transformation to (projected) original values using
% sample mean and standard deviation; 
% zVal = (xVal- xMean)/xStd ==> zVal*xStd+xMean = xVal; 
%
% INPUT: 
%   zscore = [N_samples x N_trials] data; %calcuated columnwise if N_trials
%   > 1
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

function [xVals ] = zscore_inv(zMat, xMean, xStd)

[N_OBS, N_TRIALS] = size(zMat); 
if N_OBS == 1 || N_TRIALS == 1
    if N_TRIALS > N_OBS
        zMat = zMat'; 
        [N_OBS, N_TRIALS] = size(zMat); 
    end
    %N_OBS = max(N_OBS, N_TRIALS); 
    %N_TRIALS =1 ; 
end

xVals = zeros(N_OBS, N_TRIALS); 
for tr =1:N_TRIALS
    xVals(:,tr) = zMat(:,tr)*xStd(tr)+xMean(tr); 
end

end