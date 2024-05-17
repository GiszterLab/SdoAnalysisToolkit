% Description:  Get PP data from a directory 
% Parameter:    None
% Return Value: pp_cell - Nx1 cell array where each row contains Mx2 cell for
%                         each trial (N = Trials, M = No. of Sensors)
% Note:         The directory must contain only the 


function pp_cell = getPPDataFromDirectory ()
 
    try pp_files = SAT.app_input.helper.getFiles();
    catch
        return
    end

    % Initialize the cell
    pp_cell = cell(length(pp_files), 1);

    for i = 1 : length(pp_files)
        if i == 1
            % Get the header from 1st row of 1st file
            fid = fopen(pp_files{i});
            header_table = struct2table(jsondecode(fgetl(fid)));
            pp_sensors = header_table.Properties.VariableNames;
            fclose(fid);
        end
        
        pp_original_data = readmatrix(pp_files{i});
        
        % Loop through that data to get pp data for each sensor
        new_cell = cell(length(pp_sensors), 2); % {Sensor_name(char) doubles}
        for j = 1 : length(pp_sensors)
            sensor_number = header_table.(pp_sensors{j});
            new_cell{j, 1} = pp_sensors{j};
            new_cell{j, 2} = pp_original_data(pp_original_data(:,2) == sensor_number);
        end
        pp_cell{i} = new_cell;
    end
end