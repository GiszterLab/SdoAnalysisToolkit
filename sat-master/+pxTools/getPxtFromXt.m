%% pxTools_getPxtFromXt()
% Core method for converting an time series data signal (xt) and a
% set of spike times (st) into perispike state distributions (pxt);
% pre-spike (px_x0) and post-spike (px_x1). 
%
% Different intervals for prespike/postspike distributions, delays between
% intervals, or delays between spikes and intervals are supported. 
%
% Different filter settings for smoothing drawn signal distributions are
% supported. 
%
% If nargout = 2; default to px_x0, px_x1; 
%
% INPUTS
%   xt - [1xN] Time series data signal, discretely sampled
%   st - [1xM] Discrete time indices, corresponding to events of interest
%       If left empty, calculate over ALL unique time indices in xt
%       If [NxM] Discrete time indices, assume within-sets are row-wise. 
%   signalLevels - [1 x N_STATES+1] Doubles Vector. Values correspond to the edges
%       of the bins of the signal amplitude --> state. 
%   OPTIONAL NAME-VALUE ARGS: 
%       'navg' - [1 x 2] Integer Vector. Number of bins to use in the
%           prespike(1) and postspike(2) distributions. 
%               Default = [20,20]; 
%       'smoothwid' - Integer [N>=0]. Number of states to calculate smoothing
%           exponential decay kernel over, to filter pxt. 
%               Default = 0; 
%       'smoothstd' - Double [N>=0]. Standard deviation of filtfilt
%           gaussian kernel
%               Default = 0; 
%       'n_shift'   - Integer. Position of the start of x1, given s=0; 
%               Default = 1; 
%       'z_delay'   - Integer. Delay between end of px0 and start of px1; 
%
% OUTPUTS
%   px_x0 - pre-spike state probabiilty distribution, columnwise
%   px_x1 - post-spike state probability distribution, columnwise
%   ind_x0 - Positional Indicies of xt used in px_x0
%   ind_x1 - Positional indicies of xt used in px_x1

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

function [px_t0, px_t1, ind_x0, ind_x1] = getPxtFromXt(xt, st, signalLevels, varargin)
p = inputParser; 
addOptional(p, 'navg', [20, 20]); %// NBins duration
addOptional(p, 'smoothwid', 0); 
addOptional(p, 'smoothstd', 0); 
addOptional(p, 'n_shift', 1); %// homogenous shift in start of pre/post (not delay between pre-post); 
addOptional(p, 'z_delay', 0); %delay //between// the end of prePx and start of postPx indices; (negative values possible)
parse(p, varargin{:}); 
pR = p.Results; 

%__ Necessary for single-state values
emo = @(x,varargin)ensure2DMatOrientation(x, varargin{:});

if strcmpi(st, 'all')
    %// spiketimes; if not defined, use all time points in time series
    st = 1:length(xt); 
end

% || __ Check for multi-comp__ ||
[sz_Y, sz_X] = size(st); 

if (sz_Y > 1) && (sz_X > 1)
    MULTICOMP = 1; 
else
    MULTICOMP = 0; 
end

xt= xt(:);
%_____________
N_PX0_POINTS    = pR.navg(1); 
try
    N_PX1_POINTS    = pR.navg(2); 
catch
    N_PX1_POINTS    = 0; 
end
PX_FSM_WID      = pR.smoothwid; 
PX_FSM_STD      = pR.smoothstd; 
PX_NSHIFT       = floor(pR.n_shift); 
PX_ZDELAY       = pR.z_delay; 
X_LENGTH        = length(xt); 
if MULTICOMP
    N_SPIKES = sz_X; 
    N_ROWS   = sz_Y; 
else
    N_SPIKES    = length(st); 
    N_ROWS      = 1; 
end
N_SIG_LEVELS    = length(signalLevels); 
%_____________
%%
if N_SPIKES == 0
    %// Pass empty if no spikes
    px_t0 = []; 
    px_t1 = []; 
    if nargout == 4
        ind_x0 = []; 
        ind_x1 = []; 
    end
    return
end

%% Generate positional indices for pre/post ref-point

st_row = reshape( (st+PX_NSHIFT)', 1, N_SPIKES*N_ROWS); %apply universal shift to vals BEFORE: 

if length(pR.navg) > 1 
    %// permit different sized pre-post casts (or n one at all)
    shifts = -floor(N_PX0_POINTS)+1:floor(N_PX1_POINTS); 
    indices=repmat(st_row,N_PX0_POINTS + N_PX1_POINTS,1)+repmat(shifts',1,N_SPIKES*N_ROWS);
else 
    %// symmetrical pre/post intervals
    shifts=-floor(N_PX0_POINTS)+1:floor(N_PX0_POINTS);
    indices=repmat(st_row,2*floor(N_PX0_POINTS),1)+repmat(shifts',1,N_SPIKES*N_ROWS);
end

if PX_ZDELAY ~=0
    %// add z_delay to postPx idx
    zD = zeros(size(indices)); 
    zD(PX_NSHIFT+1:end,:) = PX_ZDELAY; 
    indices = indices + zD; 
end
    
%// conform indices to within observed time series
indices(indices<1)=1;
indices(indices>X_LENGTH)=X_LENGTH;
indices = round(indices);

%//States in pre-post observations ...
ind_x0 = indices(1:N_PX0_POINTS,:); 
ind_x1 = indices(N_PX0_POINTS+1:end,:); 

%% Determine probability of State
xLevels = discretize(xt, signalLevels); 
x0_rows = emo(xLevels(ind_x0), N_PX0_POINTS);
x1_rows = emo(xLevels(ind_x1), N_PX1_POINTS); 

% __ Call to CORE (Allow work-around for direct state estimation)
N_STATES = length(signalLevels)-1; 
CALC_X1 = sum(nnz(pR.navg)) > 1; 

[px_t0, px_t1] = pxTools.get_pxt_core(x0_rows, x1_rows, N_STATES, PX_FSM_WID, PX_FSM_STD, CALC_X1); 

if MULTICOMP 
    %// Reparse; 
    px_t0 = reshape(px_t0, N_SIG_LEVELS-1, N_SPIKES, N_ROWS); 
    px_t1 = reshape(px_t1, N_SIG_LEVELS-1, N_SPIKES, N_ROWS); 
    if N_PX0_POINTS > 1
        ind_x0 =reshape(ind_x0, N_SIG_LEVELS-1, N_SPIKES, N_ROWS);
    end
    if N_PX1_POINTS > 1
        ind_x1 =reshape(ind_x1, N_SIG_LEVELS-1, N_SPIKES, N_ROWS); 
    end
end
    
if nargout == 2
    ind_x0  = []; 
    ind_x1  = []; 
end

1; 
end