%% pxTools.px_sharpen
% 
% Method to sharpen a probability distribution by reversing gaussian blur.
% (AKA Kernel sharpening or accretion)
% 
% INPUTS: 
%   - px0   [N_STATES,1] initial distribution to sharpen. 
%   - K     Scaling factor. K < 1 Diffusion | K = 1 Maintain | K > 1
%               Sharpen
%   - N_STEPS   Number of iterations to sharpen. (Default = 1); 
 %                  if 'inf' -->  walk the gradient. 
%   - 'filterWid' [numeric] (Default = 1); 
%   - 'filterStd' [numeric] (Default = 1); 
% OUTPUTS: 
%   - px_inv [N_STATES,1] final sharpened distribution. 
%   - px_te  [N_STATES,N_STEPS] p(x) time evolution from initial to final
%       state.

function [px_inv, px_te] = px_sharpen(px0, K, N_STEPS, vars)
arguments
    px0
    K       = 1.1; % K>1 sharpen; K<1 diffuse
    N_STEPS = 1; 
    vars.filterWid = 1; 
    vars.filterStd = 1; 
end

N_STATES = length(px0); 

% ___ >> Generate the H0 Kernel Stack <<______________
H0 = pxTools.getH0Array(N_STATES, vars.filterWid, vars.filterStd); 
H1 = eye(N_STATES); 

L = zeros(N_STATES,N_STATES,N_STATES); 
M = zeros(N_STATES,N_STATES,N_STATES); 
% Generate SDOs for each reverse-diffusion states
for xx = 1:N_STATES
   px0_x = H0(:,xx); 
   px1_x = H1(:,xx); 
   M(:,:,xx) = px1_x*px0_x'; 
   L(:,:,xx) = px1_x*px0_x' - diag(px0_x); % V3
end
Ln = SAT.sdoUtils.normsdo(L,M); 
% __ >>

if isinf(N_STEPS)
    % Run the gradient
    grad = inf; 
    TOL = 0.00001; 
    px00 = px0; 
    %px01 = px0; 
    while grad > TOL
        px      = px00; 
        px3    = permute(px, [3,2,1]); 
        scv     = real(px3.^K); 
        scv     = scv./sum(scv,3); 
        Lscl    = pagemtimes(Ln, scv); % Scale by mass; 
        Lsum    = sum(Lscl,3);  %resum.  
        px01    = Lsum*px+px; 
        px01    = px01./sum(px01); 
        grad    = sum(abs(px01-px00)); 
    end
    px_te  = px01; 
    px_inv = px01; 
    
else
    px_te = zeros(N_STATES, N_STEPS+1);
    px_te(:,1) = px0; 
    
    for ss = 1:N_STEPS
        px      = px_te(:,ss); 
        px3     = permute(px, [3,2,1]);  
        scv     = real(px3.^K); 
        scv     = scv./sum(scv,3); 
        Lscl    = pagemtimes(Ln, scv); % Scale by mass; 
        Lsum    = sum(Lscl,3);  %resum. 
        %
        px_te(:,ss+1)   = Lsum*px+px; 
        % _ Normalize; 
        px_te(:,ss+1)   = px_te(:,ss+1)./sum(px_te(:,ss+1)); 
        %
        %grad = sum(abs(px_te(:,ss+1)-px_te(:,ss))); 
    end
    px_inv = px_te(:,end);
end

 
if nargout == 1
    px_te = []; 
end

end