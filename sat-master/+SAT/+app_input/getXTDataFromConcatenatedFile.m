%% SAT - app_input:: 
%% getXtDataCellFromConcatenatedFile

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Get the XT data and header from concatenated XT file 
% Parameter:    xt_data - A cell array containing XT data
%               char_index - Index of row numbers where char/str row exists
%               xt_header - Header for each column of xt_data
% Return Value: xt_cell - Nx2 cell array where the {1,1} contains the header
%                         and the second column contains xt matrix data for 
%                         each trial 

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

function xt_cell = getXtDataFromConcatenatedFile (xt_data, char_index, xt_header)
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