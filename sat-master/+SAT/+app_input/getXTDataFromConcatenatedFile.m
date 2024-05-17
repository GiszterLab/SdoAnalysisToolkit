% Description:  Get the XT data and header from concatenated XT file (.csv) 
% Parameter:    xt_file_name - the file path for where the
%                              concatenated xt file is
% Return Value: xt_cell - Nx2 cell array where the {1,1} contains the header
%                         and the second column contains xt matrix data for 
%                         each trial 
% Note:         -The program expects headers at the first row, 
%               then the trial header and the data, trial header and data, ...
%               and so on
%               -A trial header can be anything as long as is a character or
%               string
function xt_cell = getXTDataFromConcatenatedFile (xt_file_name)
    % Get header and the whole xt data
    xt_data = readcell(xt_file_name);
    xt_header = xt_data(1, :);
    xt_data = xt_data(2:end, :);
    
    % Find the character index for 'trial' char
    % ** Trials Limit = 1000 **
    char_index = zeros(1, 1000);
    counter = 1;
    for i = 1 : height(xt_data)
        % If the data is a character, then this is the row 
        % where 'trial' is written
        if ischar(xt_data{i,1})
            char_index(counter) = i;
            counter = counter + 1;
        end
    end
    char_index = char_index(char_index ~= 0);
    
    % Error Check: User might forget the trial header
    if isempty(char_index)
        error("!!! Could not find the TRIAL HEADERS !!!")
    end

    % Separate the trials put each trial inside each cell
    xt_cell = cell(length(char_index), 2);
    % Insert the header data
    xt_cell{1, 1} = xt_header;
    for i = 1 : length(char_index)
        % The assignment behaves differently at the last trial
        if i == length(char_index)
            xt_cell{i, 2} = cell2mat(xt_data(char_index(i) + 1 : end, :));
        else
            xt_cell{i, 2} = cell2mat(xt_data(char_index(i) + 1 : char_index(i+1) - 1, :));
        end
    end
end