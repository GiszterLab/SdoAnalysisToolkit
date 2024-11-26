%% SAT - app_input:: 
%% getXtDAtaFromDirectory


% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Get XT data from multiple XT files 
% Parameter:    xt_files - A cell array containing files' path
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

function xt_cell = getXTDataFromDirectory (xt_files)
arguments
    xt_files (1,:) cell 
end

    % Initialize the cell
    xt_cell = cell(length(xt_files), 2);

    for i = 1 : length(xt_files) 
        if i == 1
        opts = detectImportOptions(xt_files{i});
        old_header_cell = opts.VariableNames;
        end

        % Check if all the headers for XT Files are the same
        if i > 1 
            opts = detectImportOptions(xt_files{i});
            current_header_cell = opts.VariableNames;
            if ~SAT.app_input.helper.checkColumns(old_header_cell, current_header_cell)
                error_file = split(xt_files{i},'\');
                error("!!!You don't have the same header at %s!!!", error_file{end});
            end
            old_header_cell = current_header_cell;
        end

        % Insert the XT data
        xt_cell{i,2} = readmatrix(xt_files{i});

        % At the last loop, after checking headers have matched, insert
        if i == length(xt_files)
            xt_cell{1,1} = old_header_cell;
        end
    end
end