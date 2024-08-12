% Description:  Get the PP data from concatenated PP file (.csv) 
% Parameter:    pp_data - A cell array containing pp data with only two 
%                         columns, the first column contains the time and
%                         the second column contains the interger
%                         representation of sensor
%               char_index - Index of row numbers where char/str row exists
%               pp_header_struct - A struct containing sensor names and
%                                  integer representation of them
% Return Value: pp_cell - Nx1 cell array where each row contains Mx2 cell for
%                         each trial (N = Trials, M = No. of Sensors)

function pp_cell = getPPDataFromConcatenatedFile (pp_data, char_index, pp_header_struct)
arguments
    pp_data (:,2) cell
    char_index (1,:) double {mustBeInteger, mustBePositive}
    pp_header_struct struct
end
    
    % Get the sensors' cell
    pp_sensors = fields(pp_header_struct);

    % Initialize a cell array to store each trial
    pp_cell = cell(length(char_index), 1);
    
    % Separate the trials and put each trial inside each cell
    for i = 1 : length(char_index)
        % The assignment behaves differently at the last index
        if i == length(char_index)
            pp_cell{i} = cell2mat(pp_data(char_index(i) + 1 : end, :));
        else
            pp_cell{i} = cell2mat(pp_data(char_index(i) + 1 : char_index(i+1) - 1, :));
        end
        
        % Loop through that data to get pp data for each sensor
        new_cell = cell(length(pp_sensors), 2); % {Sensor_name(char) doubles}
        for j = 1 : length(pp_sensors)
            sensor_number = pp_header_struct.(pp_sensors{j});
            new_cell{j, 1} = pp_sensors{j}; % Get sensor's name
            new_cell{j, 2} = pp_cell{i}(pp_cell{i}(:, 2) == sensor_number)'; % Get spikes (Column Data Only)
        end
        pp_cell{i} = new_cell;
    end
end