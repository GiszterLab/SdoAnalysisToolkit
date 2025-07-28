%% deal2struct()
% Used for setting to multidimensional elements
function [S] = deal2struct(S, sField, val) 
[xx,yy] = size(S); 
for x=1:xx
    for y=1:yy
         S(x,y).(sField) = val; 
    end
end
end