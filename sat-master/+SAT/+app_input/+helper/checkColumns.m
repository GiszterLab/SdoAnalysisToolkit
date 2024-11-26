%% SAT - app_input:: 
%% helper.checkColumns


% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Check whether the old_column_cell and current_column_cell 
%               has the same character data
% Parameters:   old_column_cell - 1xN cell containing char/str
%               new_column_cell - 1xN cell containing char/str
% Return Value: same_column - logical value
% Note:         The cell must contain all the string/char data on the
%               first row
% Use:          This is used for checking whether the headers at each xt
%               file are the same


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

function same_column = checkColumns(old_column_cell, current_column_cell)
    same_column = true;
    for i = 1 : width(old_column_cell)
        % Strip the whitespaces
        old_str = strip(old_column_cell{1, i});
        current_str = strip(current_column_cell{1, i});

        % Compare (case-insensitive)
        if ~strcmpi(old_str, current_str)
            same_column = false;
            break;
        end
    end
end