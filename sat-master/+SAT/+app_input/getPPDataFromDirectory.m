%% SAT - app_input:: 
%% getPpDataFromDirectory

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Get PP data from multiple PP files
% Parameter:    pp_files - A cell array containing files' path
% Return Value: pp_cell - Nx1 cell array where each row contains Mx2 cell for
%                         each trial (N = Trials, M = No. of Sensors)

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

function pp_cell = getPpDataFromDirectory (pp_files)
arguments
    pp_files (:,1) cell
end

    % Initialize the cell
    pp_cell = cell(length(pp_files), 1);

    % Find the header from each row of all files
    % if not found, raise error
    for i = 1 : length(pp_files)
        fid = fopen(pp_files{i});
        line = fgetl(fid);
        fclose(fid);
        try
            header_table = struct2table(jsondecode(line));
            pp_sensors = header_table.Properties.VariableNames;
            break
        catch
            if i == length(pp_files)
                error("!!! WHERE IS PP HEADER? !!!");
            end
            continue
        end
    end

    % Loop through each file
    for i = 1 : length(pp_files)
        pp_original_data = readmatrix(pp_files{i});
        
        % Loop through that data to get pp data for each sensor
        new_cell = cell(length(pp_sensors), 2); % {Sensor_name(char) doubles}
        for j = 1 : length(pp_sensors)
            sensor_number = header_table.(pp_sensors{j});
            new_cell{j, 1} = pp_sensors{j}; % Get sensor's name
            new_cell{j, 2} = pp_original_data(pp_original_data(:,2) == sensor_number)'; % Get spikes (Column Data Only)
        end
        pp_cell{i} = new_cell;
    end
end