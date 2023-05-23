%% get_pxt_core 
% For use within the SDO Analysis Toolkit.
% Direct kernel method for getting state probability distributions; 
%  --> preprocessed data from getting the distributions from state; 
%
% Should be effective for the 'multicomp' variant of the getPxt Script

% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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

function [px_t0, px_t1] = get_pxt_core(x0_rows,x1_rows, N_STATES, PX_FSM_WID, PX_FSM_STD, CALC_X1) 

N_PX0_POINTS = size(x0_rows,2); 
N_PX1_POINTS = size(x1_rows,2); 

px_t0 = zeros(N_STATES, N_PX0_POINTS); 
%px_t0 = zeros(N_STATES, N_SPIKES*N_ROWS);
if CALC_X1
    px_t1 = px_t0;
end
for xi = 1:N_STATES %// for every state;
    %// sum states matching level, normalize to 1; 
    if ~isempty(x0_rows)
        px_t0(xi,:) = sum(x0_rows == xi,1)/N_PX0_POINTS;
    end
    if CALC_X1
        px_t1(xi,:) = sum(x1_rows == xi, 1)/N_PX1_POINTS; 
    else
        %// px0/px1 are same size
        px_t1(xi,:) = sum(x1_rows == xi, 1)/N_PX0_POINTS; 
    end
end
%% Filter/Smooth Distributions

if PX_FSM_WID > 0
    %// Gaussian equation 
    kn = getgausskernel(PX_FSM_WID, PX_FSM_STD); 
    px_t0 = ffxt(kn,1,px_t0); 
    px_t1 = ffxt(kn,1,px_t1); 
end

%__ posthoc norm to 1
px_t0 = normpdfcol2unity(px_t0); 
px_t1 = normpdfcol2unity(px_t1); 

end