% Description:  Get the XT data and header from concatenated XT file 
% Parameter:    xt_data - A cell array containing XT data
%               char_index - Index of row numbers where char/str row exists
%               xt_header - Header for each column of xt_data
% Return Value: xt_cell - Nx2 cell array where the {1,1} contains the header
%                         and the second column contains xt matrix data for 
%                         each trial 

function xt_cell = getXTDataFromConcatenatedFile (xt_data, char_index, xt_header)
arguments
    xt_data (:,:) cell
    char_index (1,:) double {mustBeInteger, mustBePositive}
    xt_header (1,:) cell
end

    % Separate the trials put each trial inside each cell
    xt_cell = cell(length(char_index), 2);
    for i = 1 : length(char_index)
        % The assignment behaves differently at the last trial
        if i == length(char_index)
            xt_cell{i, 2} = cell2mat(xt_data(char_index(i) + 1 : end, :));
        else
            xt_cell{i, 2} = cell2mat(xt_data(char_index(i) + 1 : char_index(i+1) - 1, :));
        end
    end

    % ***** This is not perfect, if a user has no header at all at the 
    % first few rows, this will omit that trial *****
    % Filter out empty values in the second column
    % This happens when there are consecutive char/string rows
    empty_row_logical = cellfun("isempty", xt_cell(:,2));
    xt_cell(empty_row_logical, :) = [];

    % Insert the header data
    xt_cell{1, 1} = xt_header;
end