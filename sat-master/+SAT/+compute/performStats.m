%% computeSdo.performStats
% Given the assembled 'sdo' structure, calculate the Knullback-Leibler
% Divergence (KLD) metrics from the Monte Carlo shuffled-spike and
% background null hypotheses. 
% Note that the column-sum of the joint SDO is the average pre-spike
% distribution, and the row-sum of the joint SDO is the average post-spike
% distribution;  
%
% There are 4 sets of comparisions to be drawn: 
%   1. Unit vs. Shuffle (All)
%   2. Unit vs. Background
%   3. Shuffle (all) vs. Background
%   4. Shuffle (all) vs. Shuffle (mean)
%
% There are 6 Tests of significance we perform
%   1. P(x,0) tuning (i.e. non-normalized joint matrix sum)
%       --> When does the spike fire
%   2. jSDO matrixwise distance (px0 normalized)
%       --> Is there a difference in input-output, relative to when the
%       spike fires
%   3. dSDO matrixwise distance (px0 normalized)
%       --> Is there a difference in the mapping
%   4. dSDO significance elements (px0 normalized)
%       --> Are there specific places of x0-->dx1 which differ?
%       - Condense shuffles down to mean+std
%   5. Biased directional effects
%   6. Probability of directional SDO effecs?

%
% PREREQUISITES: 
%   computeSdo.PopulateSDOArray()
%
% INPUT: 
%   'sdo' struct
% OUTPUT:
%   'sdo' structure matrix; statistics appended

% Trevor S.  Smith, 2022
% Drexel University College of Medicine

% 2024- update to allow for individual combinations of stats. 

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

function sdoStruct = performStats(sdoStruct, USE_XT_CHANNELS, USE_PP_CHANNELS)
if ~exist("USE_XT_CHANNELS", 'var')
    USE_XT_CHANNELS = 1:length(sdoStruct); 
end
if ~exist("USE_PP_CHANNELS", 'var')
    USE_PP_CHANNELS = 1:length(sdoStruct(1).sdos); 
end
N_XT_CHANNELS = length(USE_XT_CHANNELS); 
N_PP_CHANNELS = length(USE_PP_CHANNELS); 

%
sFields = {'Unit', 'Bkgd', 'Shuff', 'MeanShuff'};
nFields = length(sFields); 

ii = 1; 
x_sFields = cell(nFields.^2, 1); 
for x1_i = 1:nFields
    x1 = sFields{x1_i}; 
    for x2_i = 1:nFields
        x2 = sFields{x2_i}; 
        fName = strcat(x1, '_v_', x2); 
        x_sFields{ii} = fName; 
        ii = ii+1; 
    end
end
statStruct = cell2struct(cell(nFields.^2,1), x_sFields);

for m = 1:N_XT_CHANNELS
    m_i = USE_XT_CHANNELS(m); 
    for u = 1:N_PP_CHANNELS
        u_i = USE_PP_CHANNELS(u); 
        %__________________________________________________________________

        % __ Assignment; 
        % // these generate structures of normed ('rescaled')/non-normed; 
        [dSdo, jSdo, rdSdo, rjSdo] = SAT.sdoUtils.get_UnitBkgdShuff_Matrices(sdoStruct, m_i, u_i); 

        % __ Measure the internal distance for ALL combinations
        for x1_i = 1:nFields
            x1 = sFields{x1_i}; 
            for x2_i = 1:nFields
                x2 = sFields{x2_i}; 
                    refField = strcat(x1, '_v_', x2); 

                    if isempty(jSdo.(x1)); continue; end
                    if isempty(jSdo.(x2)); continue; end

                    % ______ Test Joint Distributions for Deviations 
                    % No assumptions on priors
                    [statStruct.(refField).kld_px0_px0Normed, ...
                        statStruct.(refField).kld2_px1px0_px0Normed, ...
                        statStruct.(refField).kld_px1_x0_px0Normed] = SAT.compute.KLDMeasures(jSdo.(x1), rjSdo.(x2)); 
                    % Assuming the same priors
                    [statStruct.(refField).kld_px0_raw, ...
                        statStruct.(refField).kld2_px1px0_raw, ...
                        statStruct.(refField).kld_px1_x0_raw] = SAT.compute.KLDMeasures(jSdo.(x1), jSdo.(x2));               
                    %______ Measure Internal Variance (Matrix-wise)
                    statStruct.(refField).sse_sdoMat_px0Normed = sum((rdSdo.(x1) - rdSdo.(x2)).^2, [1,2]); 
                    statStruct.(refField).sse_px1px0_px0Normed = sum((rjSdo.(x1) - rjSdo.(x2)).^2, [1,2]); 
                    
                    % _______ Test SDOs Matrices for State-Dependent Biases
                    % __ Reparameterized
                    upDown_px0Normed_x1     = matTriangle_up_down(rdSdo.(x1), 'difference' );
                    upDown_px0Normed_x2     = matTriangle_up_down(rdSdo.(x2), 'difference' ); 
                    % __ "raw" 
                    upDown_raw_x1           = matTriangle_up_down(dSdo.(x1), 'difference' );
                    upDown_raw_x2           = matTriangle_up_down(dSdo.(x2), 'difference' );  
                    %
                    statStruct.(refField).se_upDown_xWise_raw = ...
                        (upDown_raw_x1 - upDown_raw_x2).^2; % Squared error
                    statStruct.(refField).se_upDown_xWise_px0Normed = ...
                        (upDown_px0Normed_x1 - upDown_px0Normed_x2).^2; % Squared Error
                    statStruct.(refField).sse_upDown_raw = ....
                        sum((upDown_raw_x1 - upDown_raw_x2).^2, 2);  % Sum-of-squared error
                    statStruct.(refField).sse_upDown_px0Normed = ...
                        sum((upDown_px0Normed_x1 - upDown_px0Normed_x2).^2 ); % sum-of-squared Error
            end
        end
        sdoStruct(m_i).stats{1,u_i}.comparisons = statStruct; 
    end
end

end