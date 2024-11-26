%% SAT - app_input:: 
%% fill_xtdc

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Create an XT data cell object for SMM
% Parameters:   xt_cell - Nx2 cell where N is trials
%                         The headers are at {1,1} position
%                         The 2nd column has all the xt data
%               sampleR - Sampling Rate for EMG
% Return Value: xtdc - xtDataCell object

%_______________________________________
% Copyright (C) 2024 Phone Kyaw
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

function xtdc = fill_xtdc(xt_cell, sampleR)
    arguments
        xt_cell (:,2) cell
        sampleR (1,1) double {mustBeNonnegative}
    end

    % Initialize xtDataHolder object
    xt_data_holder = SAT.xtDataHolder_new(height(xt_cell), width(xt_cell{1,2}));
    
    % Loop through each trial
    for i = 1 : width(xt_data_holder)
        % Loop through each emg channel
        for j = 1 : length(xt_data_holder{1,i})
    
            % Insert raw data
            xt_data_holder{1,i}(j).raw = xt_cell{i,2}(:,j)'; % column data required
            % Insert envelope data
            xt_data_holder{1,i}(j).envelope = xt_cell{i,2}(:,j)'; % column data required
    
            % Insert sensor's name
            xt_data_holder{1,i}(j).sensor = xt_cell{1,1}{j};

            % Insert frequency
            xt_data_holder{1,i}(j).fs = sampleR; 
        end
        
        % Insert times
        xt_data_holder{1,i}(1).times = (0 : 1/sampleR : (1/sampleR) * (height(xt_cell{i,2})-1))'; % row data required
    end

    % After filling the holder, initialize xt data cell and insert it
    xtdc = xtDataCell(width(xt_data_holder), length(xt_data_holder{1,1}));
    xtdc.import(xt_data_holder);
end