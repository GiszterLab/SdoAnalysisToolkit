% Hypothesis 3: STA

% Perhaps this is the 'change' of state? (i.e. spike-effects); 

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
% Drexel University College of Medicine
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.

function [normMat, L_mat, M_mat] = getH3(nStates, at0, at1, signalLevels, vars) %x0, x1, vars)
arguments
    nStates
    at0
    at1
    signalLevels
    vars.type {mustBeMember(vars.type, {'L', 'M'})} = 'L'; 
    vars.method {mustBeMember(vars.method, {'dpx', 'px'})} = 'px'; %idk
end

% ... ?? How do we want to best do this? 

% _LOTS of different methods; 

% 00: Could 'preprocess' the signal levels (e.g. ISA-subtract)

%  1. measure the 'dx' 

%  2. Take average state

%  3. Feed it into a VAE? % What about time-position information?


N_PX0_PTS = size(at0,1); 
N_PX1_PTS = size(at1,1); 

% __ Simple mean-leveled average___ 
s_raw = mean([at0; at1],2); 
s = s_raw - mean(at0, 'all');


switch vars.method
    %____________________ STA as an Effect ___________________
    case {'dpx', 'effect'}
        % __ Generate a matrix by discretizing STA state EFFECTS (i.e. dpx applied
        % to each x)
        px0_t = zeros(nStates); 
        px1_t = zeros(nStates); 
        %
        for x = 1:nStates
            if ~any(isinf(signalLevels(x:x+1)))
                mean_level = mean(signalLevels(x:x+1)); 
            elseif isinf(signalLevels(x))
                %// average between next state and set back; 
                mean_level = signalLevels(x+1)-diff(signalLevels(x+1:x+2))/2; 
            else %if el 2 is inf
                mean_level = signalLevels(x)+diff(signalLevels(x-2:x-1))/2; 
            end
            %
            xx = discretize(s+mean_level, signalLevels); % average state
            px0 = histcounts(xx(1:N_PX0_PTS), (1:nStates+1), 'normalization', 'probability')'; %should be primarily one state
            px1 = histcounts(xx(N_PX0_PTS+1:N_PX0_PTS+N_PX1_PTS), (1:nStates+1), 'normalization', 'probability')';      
            %
            px0_t(:,x) = px0; 
            px1_t(:,x) = px1; 
        end
        [L_arr, M_arr, L_norm] = SAT.compute.sdo5(px0_t, px1_t); 
        %__________________________________
    case {'px', 'average'}
        %__ Convert everything into state; Take a simple conversion; 
        % 'original' STA
        x0 = discretize(at0, signalLevels); 
        x1 = discretize(at1, signalLevels); 
        px0 = histcounts(x0-0.5, [0:length(signalLevels)-1], 'normalization', 'probability');
        px1 = histcounts(x1-0.5, [0:length(signalLevels)-1], 'normalization', 'probability'); 
        % __ Direct definition
        px0_min = max(px0, 10^-10); % avoid desaturation of probability; 
       L_norm = px1'*ones(1, nStates)-eye(nStates); 
       L_arr = L_norm*diag(px0_min); 
       M_arr =  px1'*px0; 

end

switch vars.type
    case 'L'
        normMat = L_norm; 
    case 'M'
        normMat = M_arr; 
end

L_mat = L_arr; 
M_mat = M_arr; 

if nargout < 2
    M_mat = []; 
end
if nargout == 1
    L_mat = [];
end


%[H_STA, sta_fx, sta_wv, sta_err] = findSigSta(xtdc,ppdc,1,1:nUnits); 


end