%% pxTools_getCovArrFromJointArr; 
%// Resampling method to quickly convert p(X1|X0) into P(X1|X1) or P(X0|X0)

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [covArr] = pxTools_getCovArrFromJointArr(arr, OP_DIM)

if ~exist('OP_DIM', 'var')
    OP_DIM = 1; 
end

if OP_DIM == 1
    px = sum(arr,1); 
    covArr = px'*px; 
    
else
    px = sum(arr,2); 
    covArr = px*px'; 
end

end


