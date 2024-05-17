% Description:  Get the PP data and header from concatenated PP file (.csv) 
% Parameter:    pp_file_name - the file path for where the
%                              concatenated pp file is
% Return Value: pp_cell - Nx1 cell array where each row contains Mx2 cell for
%                         each trial (N = Trials, M = No. of Sensors)
% Note:         -I am expecting a json-style header at the first row, 
%               then the trial header and the data, trial header and data, ...
%               and so on
%               -A trial header can be anything as long as is a character or
%               string
function pp_cell = getPPDataFromConcatenatedFile (pp_file_name)
    % Get the header from the first line of pp file
    fid = fopen(pp_file_name);
    header_line = fgetl(fid);
    fclose(fid);
    
    pp_header_struct = jsondecode(header_line); % Structure for original pp data
    pp_sensors = fields(pp_header_struct); % Sensor Names
    
    % Use readcell to read the concatenated file
    a = readcell(pp_file_name, "NumHeaderLines", 1);
    
    % Find the character index for 'trial' char
    % ** Trials Limit = 1000 **
    char_index = zeros(1, 1000);
    counter = 1;
    for i = 1 : height(a)
        % If the data is a character, then this is the row 
        % where 'trial' is written
        if ischar(a{i,1})
            char_index(counter) = i;
            counter = counter + 1;
        end
    end
    char_index = char_index(char_index ~= 0);
    
    % Error Check: User might forget the trial header
    if isempty(char_index)
        error("!!! Could not find the TRIAL HEADERS !!!")
    end

    % Initialize a cell array to store each trial
    pp_cell = cell(length(char_index), 1);
    
    % Separate the trials and put each trial inside each cell
    for i = 1 : length(char_index)
        % The assignment behaves differently at the last index
        if i == length(char_index)
            pp_cell{i} = cell2mat(a(char_index(i) + 1 : end, :));
        else
            pp_cell{i} = cell2mat(a(char_index(i) + 1 : char_index(i+1) - 1, :));
        end
        
        % Loop through that data to get pp data for each sensor
        new_cell = cell(length(pp_sensors), 2); % {Sensor_name(char) doubles}
        for j = 1 : length(pp_sensors)
            sensor_number = pp_header_struct.(pp_sensors{j});
            new_cell{j, 1} = pp_sensors{j};
            new_cell{j, 2} = pp_cell{i}(pp_cell{i}(:, 2) == sensor_number);
        end
        pp_cell{i} = new_cell;
    end
end