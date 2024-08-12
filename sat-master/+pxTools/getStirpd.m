
% using columnwise observations of state, generate the Spike-triggered
% impulse response probability distribution (STIRPD)

% for faster generation

function stirpd = getStirpd(x0_vals, x1_vals, max_x)

t0 = size(x0_vals,1); 
t1 = size(x1_vals,1); 

xV = [x0_vals; x1_vals]; 

nt = t0+t1; 

stirpd = zeros(max_x,nt); 

for t = 1:nt
    px = histcounts(xV(t,:), (1:max_x+1)-0.5, 'Normalization','probability'); 
    stirpd(:,t) = px; 
end

1; 

end