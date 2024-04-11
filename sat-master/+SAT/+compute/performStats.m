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
%{
sTmplt = struct( ...
    'Unit', cell(1,1), ...
    'Bkgd', cell(1,1), ...
    'Shuff', cell(1,1), ...
    'MeanShuff',cell(1,1));
%}
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
        % // these generate structures of normed/non-normed; 
        [dSdo, jSdo, rdSdo, rjSdo] = SAT.sdoUtils.get_UnitBkgdShuff_Matrices(sdoStruct, m_i, u_i); 

        % __ Measure the internal distance for ALL combinations
        for x1_i = 1:nFields
            x1 = sFields{x1_i}; 
            for x2_i = 1:nFields
                x2 = sFields{x2_i}; 
                    refField = strcat(x1, '_v_', x2); 

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
                    upDown_px0Normed_x1     = matTriangle_up_down_difference(rdSdo.(x1) );
                    upDown_px0Normed_x2     = matTriangle_up_down_difference(rdSdo.(x2) ); 
                    % __ "raw" 
                    upDown_raw_x1           = matTriangle_up_down_difference(dSdo.(x1) );
                    upDown_raw_x2           = matTriangle_up_down_difference(dSdo.(x2) );                     
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
        1; 

          

    %{


            [k_px0_unit_x_bkgd, ~, ~] = SAT.compute.KLDMeasures(jSdo_Unit, rjSdo_Bkgd); 

            [KNeuronBk, KPx0NeuronBk, KCondNeuronBk] = SAT.compute.KLDMeasures(...
                jSdo_Unit, rjSdo_Bkgd); 
            %
            changeMeasureContSDO        = matTriangle_up_down_difference(dSdo_Unit); 
            changeMeasureBkgdContSDO    = matTriangle_up_down_difference(rdSdo_Bkgd); 
            changeMeasureShuffContSDO   = matTriangle_up_down_difference(rdSdo_Shuff);
            %}
        %end
%{
            %
            [KShuffBk, KPx0ShuffBk, KCondShuffBk] = SAT.compute.KLDMeasures(...
                rjSdo_Shuff, rjSdo_Bkgd); 
            %
            [KNeuronAvgShuff, KPx0NeuronAvgShuff, KCondAvgShuff] = SAT.compute.KLDMeasures(...
                jSdo_Unit, rjSdo_Shuff_mean); 
            %
            [KShuffAvgShuff, KPx0ShuffAvgShuff, KCondShuffAvgShuff] = SAT.compute.KLDMeasures(...
                jSdo_Shuff, rjSdo_Shuff_mean); 
        else
%}
        % __ R Cond; 
        %{

        %__________________________________________________________________
        %% spike v. background (common)
        
         %// test distance of neuron to background
        [KNeuronBk, KPx0NeuronBk, KCondNeuronBk] = SAT.compute.KLDMeasures(...
            jSdo_Unit, jSdo_Bkgd); 
            %{
            sdoStruct(m_i).sdosJoint{u_i},...
            sdoStruct(m_i).bkgrndJointSDO);        
            %}
        
        %changeMeasureContSDO        = matTriangle_up_down_difference(sdoStruct(m_i).sdos{u_i});
        changeMeasureContSDO        = matTriangle_up_down_difference(dSdo_Unit); 

        changeMeasureBkgdContSDO        = matTriangle_up_down_difference(dSdo_Bkgd); 
        %% N shuffles > 0
        if HAS_SHUFFLES
            
            %meanJointShuffSDO = mean(sdoStruct(m_i).shuffles{1,u_i}.SDOJointShuff,3);
            %_____

            %// distance of each spike-shuffled SDO from background SDO
            [KShuffBk, KPx0ShuffBk, KCondShuffBk] = SAT.compute.KLDMeasures(...
                jSdo_Shuff, jSdo_Bkgd); 
                %{
                sdoStruct(m_i).shuffles{1,u_i}.SDOJointShuff,...
                sdoStruct(m_i).bkgrndJointSDO); 
                %}
            %// distance of neuron sdo from mean of spike-shuffled SDO
            [KNeuronAvgShuff, KPx0NeuronAvgShuff, KCondAvgShuff] = SAT.compute.KLDMeasures(...
                jSdo_Unit, jSdo_Shuff_mean); 
                %{
                sdoStruct(m_i).sdosJoint{1,u_i},...
                meanJointShuffSDO);
                %}
            %// distance of each spike-shuffled sdo from mean of shuffled SDO
            [KShuffAvgShuff, KPx0ShuffAvgShuff, KCondShuffAvgShuff] = SAT.compute.KLDMeasures(...
                jSdo_Shuff, jSdo_Shuff_mean); 
                %{
                sdoStruct(m_i).shuffles{1,u_i}.SDOJointShuff,...
                meanJointShuffSDO);
                %}
            %

            %changeMeasureShuffContSDO   = matTriangle_up_down_difference(sdoStruct(m_i).shuffles{u_i}.SDOShuff);
            changeMeasureShuffContSDO   = matTriangle_up_down_difference(dSdo_Shuff);
        else
            %// Dummy
            %meanJointShuffSDO   = []; 
            KShuffBk            = []; 
            KPx0ShuffBk         = [];
            KCondShuffBk        = []; 
            KNeuronAvgShuff     = []; 
            KPx0NeuronAvgShuff  = []; 
            KCondAvgShuff       = []; 
            KShuffAvgShuff      = []; 
            KPx0ShuffAvgShuff   = []; 
            KCondShuffAvgShuff  = []; 
            changeMeasureShuffContSDO = []; 
        end
        %end
        %_______
        %// Fill MAB Fields --> Rename these after correcting stats?

        sss = sdoStruct(m_i).stats{1,u_i}; %pass; 
        %{
        if REPARAMETERIZE
            sss.parameterization            = 'px0'; 
        else
            sss.parameterization            = 'none'; 
        end
        %}
        %
        sss.changeMeasureContSDO        = changeMeasureContSDO; 
        sss.changeMeasureShuffContSDO   = changeMeasureShuffContSDO; 
        sss.changeMeasuresBkgdContSDO   = changeMeasureBkgdContSDO; 
        sss.KL2D_neuron_bk              = KNeuronBk; 
        sss.KL2D_shuff_bk               = KShuffBk; 
        sss.KLcurr_neuron_bk            = KPx0NeuronBk; 
        sss.KLcurr_shuff_bk             = KPx0ShuffBk; 
        sss.KLcond_neuron_bk            = KCondNeuronBk; 
        sss.KLcond_shuff_bk             = KCondShuffBk; 
        sss.KL2D_neuron_meanshuff       = KNeuronAvgShuff; 
        sss.KL2D_shuff_meanshuff        = KShuffAvgShuff; 
        sss.KLcurr_neuron_meanshuff     = KPx0NeuronAvgShuff; 
        sss.KLcurr_shuff_meanshuff      = KPx0ShuffAvgShuff; 
        sss.KLcond_neuron_meanshuff     = KCondAvgShuff; 
        sss.KLcond_shuff_meanshuff      = KCondShuffAvgShuff; 
        %sss.meanShuffSDO                = meanDeltaShuffSDO; 
        %sss.meanJointShuffSDO           = meanJointShuffSDO; 
        %___

        sdoStruct(m_i).stats{1,u_i} = sss; %pass back; 
        %}
        sdoStruct(m_i).stats{1,u_i}.comparisons = statStruct; 
    end
end

end