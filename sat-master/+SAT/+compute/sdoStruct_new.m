%% computeSDO_new()
% Construct an empty 'sdo' structure array and populate it with the
% relevant fields; 

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


function [sdo] = sdoStruct_new(N_XT_CHANNELS, N_PP_CHANNELS)
if ~exist("N_PP_CHANNELS", "var")
    N_PP_CHANNELS = 1; 
end

sdo = struct( ...
    'signalType',       cell(1,N_XT_CHANNELS), ...
    'neuronNames',      cell(1,N_XT_CHANNELS), ...
    'levels',           cell(1,N_XT_CHANNELS), ...
    'unit',             cell(1,N_XT_CHANNELS), ...
    'sdosJoint',        cell(1,N_XT_CHANNELS), ...
    'sdos',             cell(1,N_XT_CHANNELS), ...
    'bkgrndJointSDO',   cell(1,N_XT_CHANNELS), ...
    'bkgrndSDO',        cell(1,N_XT_CHANNELS), ...
    'shuffles',         cell(1,N_XT_CHANNELS), ...
    'stats',            cell(1,N_XT_CHANNELS), ...
    'params',           cell(1,N_XT_CHANNELS), ... 
    'stirpd',           cell(1,N_XT_CHANNELS));%, ...  %recent update; 

% ____ 
% __>>> Predefine subfields for clarity
% -->> These need to mirror the fields populated in 'performStats.m' and 'testStatSig.m'

statFields = {'Unit', 'Bkgd', 'Shuff', 'MeanShuff'}; 
nFields = length(statFields); 
ii = 1; 
x_sFields = cell(nFields.^2, 1); 
for x1_i = 1:nFields
    x1 = statFields{x1_i}; 
    for x2_i = 1:nFields
        x2 = statFields{x2_i}; 
        fName = strcat(x1, '_v_', x2); 
        x_sFields{ii} = fName; 
        ii = ii+1; 
    end
end
compStruct = cell2struct(cell(nFields.^2,1), x_sFields);

stats_struct = struct( ... 
    'comparisons',              compStruct, ... 
    'pVal',                     0, ...
    'nEvents',                  0); 
%{
    'changeMeasureContSDO',     cell(1), ... 
    'changeMeasureShuffContSDO',cell(1), ... 
    'KL2D_neuron_bk',           cell(1), ... 
    'KL2D_shuff_bk',            cell(1), ... 
    'KLcurr_neuron_bk',         cell(1), ... 
    'KLcurr_shuff_bk',          cell(1), ... 
    'KLcond_neuron_bk',         cell(1), ... 
    'KLcond_shuff_bk',          cell(1), ... 
    'KL2D_neuron_meanshuff',    cell(1), ... 
    'KL2D_shuff_meanshuff',     cell(1), ...
    'KLcurr_neuron_meanshuff',  cell(1), ... 
    'KLcurr_shuff_meanshuff',   cell(1), ... 
    'KLcond_neuron_meanshuff',  cell(1), ... 
    'KLcond_shuff_meanshuff',   cell(1), ... 
    'isSig_2D',                 false, ...
    'isSig_Px0',                false, ...
    'isSig_IncreaseDecrease',   false, ...
    'nEvents', 0); 
%}

shuffle_struct = struct( ... 
    'SDOShuff',             cell(1), ... 
    'SDOJointShuff',        cell(1), ... 
    'SDOShuff_mean',        cell(1), ... 
    'SDOShuff_std',         cell(1), ... 
    'SDOJointShuff_mean',   cell(1), ... 
    'SDOJointShuff_std',    cell(1)); 


for m = 1:N_XT_CHANNELS
    sdo(m).neuronNames  = cell(1,N_PP_CHANNELS); 
    sdo(m).sdosJoint    = cell(1,N_PP_CHANNELS); 
    sdo(m).sdos         = cell(1,N_PP_CHANNELS); 
    sdo(m).shuffles     = repelem({shuffle_struct}, 1, N_PP_CHANNELS); 
    sdo(m).stats        = repelem({stats_struct}, 1, N_PP_CHANNELS); 
end

end