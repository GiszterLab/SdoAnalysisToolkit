%% pairedResample
%
% Used when we have paired data which we are 'resampling'; ensures that the
% shuffle points which are randomly drawn from one group matches the other
% groups EXACTLY. 
%
% Returns a tensor of the observations for later manipulation; 
%
% Assume data is a [nObservations x nGroups], with each row corresponding
% to a paired observation. 

function [dataShuff] = pairedresample(dataMat, N_SHUFFLES)

[N_OBS, N_GROUPS] = size(dataMat); 

LI_0 = randi(N_OBS, N_OBS, N_SHUFFLES); 
LI = reshape(LI_0, N_SHUFFLES, N_OBS)'; %assume N_SHUFF > N_OBS; 

dataShuff = zeros(N_OBS, N_GROUPS, N_SHUFFLES); 

for gg = 1:N_GROUPS
    shuff = dataMat(LI,gg); 
    
    dataShuff(:,gg,:) = reshape(shuff, N_OBS, []); 
end


end