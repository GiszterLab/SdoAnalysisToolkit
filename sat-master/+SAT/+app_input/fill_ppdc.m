%% SAT - app_input:: 
%% fill_ppdc

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Return a PP data cell object for SMM
% Parameters:   pp_cell - Nx1 cell where N is a trial. Inside each
%               cell is a Mx2 cell where M is sensor and the second column
%               is the activation time
%               frequency - sampling rate
% Return Value: ppdc - ppDataCell object

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

function ppdc = fill_ppdc (pp_cell, frequency)
arguments
    pp_cell (:,1) cell
    frequency (1,1) double {mustBePositive} = 30000
end
    % Initialize PP data holder object
    pp_data_holder = SAT.ppDataHolder_new(height(pp_cell), height(pp_cell{1}));
    
    for i = 1 : height(pp_cell)
        for j = 1 : height(pp_cell{i})
            % Fill in all the pp values
            pp_data_holder{1,i}(j).sensor = pp_cell{i}{j,1};
            pp_data_holder{1,i}(j).times = pp_cell{i}{j,2};
            pp_data_holder{1,i}(j).envelope = pp_cell{i}{j,2};
            pp_data_holder{1,i}(j).nEvents = width(pp_cell{i}{j,2});
            pp_data_holder{1,i}(j).fs = frequency;
        end
    end

    % After filling the holder, initialize pp data cell and insert it
    ppdc = ppDataCell(width(pp_data_holder), length(pp_data_holder{1,1}));
    ppdc.import(pp_data_holder);
end