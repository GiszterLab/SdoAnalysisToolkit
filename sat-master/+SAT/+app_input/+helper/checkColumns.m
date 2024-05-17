% Description:  Check whether the old_column_cell and current_column_cell 
%               has the same character data
% Parameters:   old_column_cell - 1xN cell containing char/str
%               new_column_cell - 1xN cell containing char/str
% Return Value: same_column - logical value
% Note:         The cell must contain all the string/char data on the
%               first row
% Use:          This is used for checking whether the headers at each xt
%               file are the same
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