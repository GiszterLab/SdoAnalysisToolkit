%% dataCell.calculate.spikeCorrelogram
%
% Used as a method for extracting the spike-spike correlograms, useful to
% determining patterns of relationships or mixed activity between neurons,
% or validating the quality of the spike-sorting when applied to self. 
%
% INPUTS
%   - ref_st    - [1xN] vector; Reference spike train (time or indices)
%   - que_st    - [1xM] vector; Queryt spike train 
% NAME-VALUE PAIRS:
%   - 'dt'      - Time resolution for histograms (Sec). Default - 0.005
%   - 'leadDura'- Time Duration before spiketime to draw correlogram over
%       (Sec). Default = 0.2 NOTE: Positive; 
%   - 'lagDura' - Time Duration after spiketime to draw correlgram over
%       (Sec). Default = 0.2 NOTE: Positive; 
%   - 'norm'    - Whether to normalize histograms (hist/nspikes*dt)
%_____________________________________________
% Trevor Smith, 2025
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




function [hh, sampPct] = spikeCorrelogram(ref_st, que_st, vars)
arguments
    ref_st          % reference
    que_st          % reference
    vars.dt         = 0.005; 
    vars.leadDura   = 0.200; 
    vars.lagDura    = 0.200; 
    vars.autoISI    = 0; % Temporary; for debugging; 
    vars.norm       = 0; 
end

nSpikes_ref = length(ref_st); 
nSpikes_que = length(que_st); 

MAX_ARR = 1e9; 

if (nSpikes_ref * nSpikes_que) > MAX_ARR
    LOW_MEMORY = 1; 
else 
    LOW_MEMORY = 0; 
end

% time ranges and plotting vector; 
tRng = (-vars.leadDura-1/2*vars.dt): vars.dt: (vars.lagDura+1/2*vars.dt); 
tVect = (-vars.leadDura: vars.dt: vars.lagDura); % for plotting; 

if LOW_MEMORY == 0
    x_arr = ref_st'-que_st; %difference in time between each reference spiketime and each query spike time; 

    % Now just mask for values +/- of target range; 
    maskArr_pos = (x_arr <= vars.lagDura); 
    maskArr_neg = (x_arr >= -vars.leadDura); 
    maskArr = maskArr_neg & maskArr_pos; 
    %
    deltas = x_arr(maskArr); % 1D hist; 
    %
    sampPct = sum(any(x_arr))/nSpikes_que; 
    hh = histcounts(deltas, tRng); 
else
    binWid = ceil(MAX_ARR/nSpikes_que); 
    nBins = ceil(nSpikes_ref/binWid); 
    sampPct_raw = 0; 
    hh = zeros(1, length(tVect)); 
    for b = 1:nBins
        t0 = (b-1)*binWid+1; 
        t1 = b*binWid; 
        %{
        % // wrong?
        if t1 > nSpikes_que
            t1 = nSpikes_que; 
        end
        %}
        if t1 > nSpikes_ref
            t1 = nSpikes_ref;
        end
        ref_st_bin = ref_st(t0:t1); 
        q_t0 = find(que_st>ref_st(t0),1)-1; % find the start of the query region;  
        if q_t0 == 0
            % no overlap
            continue; 
        end
        q_t1 = find(que_st(q_t0:end)>ref_st(t1),1)-1; % find the end of the query region; 
        q_t1 = q_t1 + q_t0; 
        if (q_t1 - q_t0) < 1
            if (b < nBins)
                continue;
            elseif all(ref_st(t1) < que_st(q_t0:end))
                % no overlap; 
                continue; 
            else
                q_t1 = t1; %final endpoint; 
            end
        end
        
        que_st_bin = que_st(q_t0:q_t1); 
        x_arr_bin = ref_st_bin' - que_st_bin; 
        % __ Find spikes in reference near query
        maskArr_pos = (x_arr_bin <= vars.lagDura); 
        maskArr_neg = (x_arr_bin >= -vars.leadDura); 
        maskArr = maskArr_neg & maskArr_pos; 
        % 
        deltas_bin = x_arr_bin(maskArr); 
        %
        sampPct_raw = sampPct_raw + sum(any(maskArr)); 
        %
        hh = hh + histcounts(deltas_bin, tRng); 
    end
    %
    sampPct = sampPct_raw/nSpikes_que; 
end

if vars.norm
    hh = hh/sum(hh)*vars.dt;  
end

if vars.autoISI
    hh(1, round(1/vars.dt*vars.leadDura)+1) = 0; %Don't count self-spikes; 
end

if nargout == 1
    sampPct = [];
end

end