% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Get PP data from multiple PP files
% Parameter:    pp_files - A cell array containing files' path
% Return Value: pp_cell - Nx1 cell array where each row contains Mx2 cell for
%                         each trial (N = Trials, M = No. of Sensors)

function pp_cell = getPPDataFromDirectory (pp_files)
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