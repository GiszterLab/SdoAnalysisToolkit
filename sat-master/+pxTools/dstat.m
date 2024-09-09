
% Get the D-Statistic; 
% Maximum absolute difference between two distributions; 
% Test statistic for the KS-test

function D = dstat(px_0, px_1)
%// assume these are column vectors of the same size 

%[sz
%[sz1_y, sz1_x] = size(px_1); 

ecdf_px0 = cumsum(px_0); 
ecdf_px1 = cumsum(px_1); 

dpx = (ecdf_px0-ecdf_px1); 

D = max(abs(dpx)); 


end