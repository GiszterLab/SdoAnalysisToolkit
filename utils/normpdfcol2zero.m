%% 
% A method to nomalize the negative components of a column vector/ SDO such 
% that the sum of the column is 0. 
%

% MAB code; 

% TS modifications; 

function out = normpdfcol2zero(arr)
%// normalize negative components of a column vector to sum zero
zi = sum(arr,1);        %bias; 
zp = sum(abs(arr),1);   %magnitude; 

%zN = (zp+zi)./(zp-zi); 

msk = repmat((zp+zi)./(zp-zi), size(arr,1),1); 

msk(arr>=0) = 1; %/apply scalar to negatives; 

out = arr.*msk; 
end
