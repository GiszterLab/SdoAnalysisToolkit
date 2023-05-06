%% zscore_inv
% Inverse a Z-score transformation to (projected) original values using
% sample mean and standard deviation; 
% zVal = (xVal- xMean)/xStd ==> zVal*xStd+xMean = xVal; 
%
% INPUT: 
%   zscore = [N_samples x N_trials] data; %calcuated columnwise if N_trials
%   > 1
% 


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