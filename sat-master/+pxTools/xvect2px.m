%% xvect2px
%// generic method for turning a state signal (1 x M) into a (M x N) array
%of 0/1, which corresponds the 'probability' of state, represented as
%sequential column vectors

% Trevor s. Smith, 2022
% Drexel University College of Medicine

function px = xvect2px(xt, MAX_X)
if ~exist('MAX_X', 'var') 
    MAX_X = max(xt); 
end

nObs = length(xt); 

px = zeros(MAX_X, nObs); 

for xx = 1:MAX_X
    xi = (xt == xx); 
    px(xx,xi) = 1; 
end

end