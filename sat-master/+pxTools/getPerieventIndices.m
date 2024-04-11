%% getPeriEventIndices
%
% Take a [N_XT_, N_OBS] set of time series, and sample at {N_PP_CH}
% time points, and extract the signal around it. 
%
% Given event times, get the indices of elements around, and
% including, the event time, given the associated parameters. 
%
% INPUTS
% - 'st' A [N_SHUFFLE, N_OBS] or {N_PP_CH,1} cell of [N_SHUFFLE, N_OBS] indices (integers)
%       corresponding to event times 
% NAME-VALUE Pairs
% - 'n_shift' = left/right shift of both pre/post indices relative to spike
%       onset
% - 'z_delay' = delay between the end of the pre indices and start of the
%       post-indices
% - 't0_nPoints'= Number of time points to include in the 'pre' event
% indices
% = 't1_nPoints' = Number of time points to include in the 'post' event
% indices
% OUTPUTS
%   - idx_t0 = {1,N_PP_CH} cell of [t0_nPoints x N_OBS x N_SHUFFLE]; if st is a double,
%       this is a doubles array
%   - idx_t1 = {1,N_PP_CH} cell of [t1_nPoints x N_OBS x N_SHUFFLE]; if st is a double,
%       this is a doubles array

% Requires MATLAB 2018 or newer

%_______________________________________
% Copyright (C) 2023 Trevor S. Smith
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
%__________________________________________

function [idx_t0, idx_t1] = getPerieventIndices(st, vars)
    arguments
        st
        vars.n_shift = 0; %note this differs from documentation...  
        vars.z_delay = 0; 
        vars.t0_nPoints {mustBeInteger} = 20; 
        vars.t1_nPoints {mustBeInteger} = 20;
        vars.maxLen = []; 
    end
    
    if ~iscell(st)
        % __ single comp 
        ISCELL = 0; 
        N_PP_CH = 1; 
        [nRows, N_PP_EVENTS] = size(st); 
        %N_PP_EVENTS = length(st); 
        st_flat = st(:)'; 
        if nRows > 1
            HAS_SHUFFLES = 1; 
        end

    else

        % __ multi comp
        ISCELL = 1; 
        N_PP_CH     = length(st); 

        nCols = cellfun(@size, st, repelem({2}, N_PP_CH,1)); 
        nRows = cellfun(@size, st, repelem({1}, N_PP_CH,1)); 

        N_PP_EVENTS = nCols; 
        tRng = zeros(1, N_PP_CH); 

        if any(nRows > 1)
            tmp = cell(N_PP_CH,1); 
            for pp = 1:N_PP_CH
                tRng(pp) = nCols(pp)*nRows(pp);  
                tmp{pp} = st{pp}(:); 
            end
            st_flat = cellvcat(tmp)'; 
            HAS_SHUFFLES = 1; 
        else
            HAS_SHUFFLES = 0; 
            st_flat = cellhcat(st); 
        end
            if iscell(st_flat) 
                st_flat = st_flat{1}; 
            end
    end
    
    st_flat = round(st_flat); 
    
    N_SPIKES = N_PP_EVENTS'*nRows; %dot product
    %N_SPIKES = sum(N_PP_EVENTS); 
    
    % Quickly generate offset grids w/ associated parameters; 
    [~, x0] = meshgrid(1:N_SPIKES, (-vars.t0_nPoints+1:0)+ vars.n_shift);
    [~, x1] = meshgrid(1:N_SPIKES, (1:vars.t1_nPoints)+ vars.n_shift + vars.z_delay);
    xCat = [x0; x1]; 
    clear x0 x1
    
    % Add spikeTime indices to grids; 
    spkIx = xCat + st_flat; 
    
    % __ Conform; 
    spkIx(spkIx<1) = 1; 
    if ~isempty(vars.maxLen)
        spkIx(spkIx>vars.maxLen) = vars.maxLen; 
    end
    
    idx_t0 = cell(1,N_PP_CH); 
    idx_t1 = cell(1,N_PP_CH); 
    
    if HAS_SHUFFLES
        t0 = 1; 
        for pp = 1:N_PP_CH
            t1 = t0+tRng(pp)-1; 
            spkMat = spkIx(1:vars.t0_nPoints,t0:t1); 
            idx_t0{pp} = reshape(spkMat, nRows(pp), nCols(pp), []); 
            spkMat = spkIx(1:vars.t1_nPoints,t0:t1); 
            idx_t1{pp} = reshape(spkMat, nRows(pp), nCols(pp), []); 
            t0 = t1+1; 
        end
    else
        t0 = 1; 
        for pp = 1:N_PP_CH
            t1 = t0+N_PP_EVENTS(pp)-1; 
            idx_t0{pp} = spkIx(1:vars.t0_nPoints,t0:t1); 
            idx_t1{pp} = spkIx(vars.t0_nPoints+1:end,t0:t1); 
            t0 = t1+1; 
        end
    end
    
    if ~ISCELL
        idx_t0 = idx_t0{1}; 
        idx_t1 = idx_t1{1}; 
    end

end