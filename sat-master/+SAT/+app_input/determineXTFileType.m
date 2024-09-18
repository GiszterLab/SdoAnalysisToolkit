% Description:  Return a xt_cell when a user inputs XT files
% Parameter:    None
% Return Value: xt_cell - Nx2 cell array where the {1,1} contains the header
%                         and the second column contains xt matrix data for 
%                         each trial
% Note:         -A trial header can be anything as long as it's a character 
%               or string
%               *** A user can input multiple XT files representing each trial 
%               as long as the header matches. If no header, make sure there
%               are no headers in all files.
%               A use can input concatenated XT file, however
%               concatenated file must always be input as ONE only. ***

function xt_cell = determineXTFileType()
arguments(Output)
    xt_cell (:,2) cell
end
    % Get the files
    files = SAT.app_input.helper.getFiles();
    % if the user inputted nothing
    if isempty(files)
        xt_cell = cell.empty(0,2);
        return
    end

    if height(files) == 1 % If only one file exists
        xt_data = readcell(files{1,1});
        char_index = SAT.app_input.helper.getTrialIndex(xt_data, 1000);

        % If there's no char/str row in file OR
        if isempty(char_index) 
            xt_cell = SAT.app_input.getXTDataFromDirectory(files);
            return
        % If there's no header at the top 
        elseif char_index(1) ~= 1
            error("!!! Insert something at the top of your file or The first Trial would not be counted !!!")
            % new_cell = cell(1,width(xt_data));
            % new_cell{1,1} = "Trial_001";
            % xt_data = [new_cell; xt_data];
            % char_index= [1 char_index];
            % char_index(2:end) = char_index(2:end) + 1;
        end

        if any(diff(char_index) > 1) % Concatenated File
            xt_header = SAT.app_input.helper.getXTHeader(xt_data, 3);
            % Filter the concatenated file
            % *** Right now, there's no need to call this function as there
            % are similar filtering code inside getXTDataFromConcatenated.m
            % ***
            % [xt_data, char_index] = SAT.app_input.helper.filterCharIndex (xt_data, char_index);
            % Call the get concatenated file function
            xt_cell = SAT.app_input.getXTDataFromConcatenatedFile(xt_data, char_index, xt_header);

        else % Normal one file
            xt_cell = SAT.app_input.getXTDataFromDirectory(files);
        end

    else % More than one file
        xt_cell = SAT.app_input.getXTDataFromDirectory(files);
    end
end

% function mustBeOneOrTwoRows(cell_array)
%     if height(cell_array) > 2
%         error('Cell array must have only one or two rows.');
%     end
% end