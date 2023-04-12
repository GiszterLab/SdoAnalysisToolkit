%% pxTools_getSdoFromJointArr; 
%// Resampling Method to quickly convert p(x1|x0) into p([x1-x0]|x0) * p(x0);
% 
% NOTE: Due to differences in sampling smoothing, the extracted 'sdoMat'
% will not exactly resemble the spike-triggered sdo extracted with
% 'computeSDO.m', but will grossly approximate it. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function sdoMat = pxTools_getSdoFromJointArr(arr)

sumMag = sum(sum(arr)); 
% Norm to 1
arr = arr/sumMag; 

px0 = sum(arr,1); %colsum
px1 = sum(arr,2); %rowsum

dpx = px1-px0'; 

sdoMat = dpx*px0; 

end