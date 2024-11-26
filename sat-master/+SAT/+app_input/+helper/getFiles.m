%% SAT - app_input:: 
%% helper.getFiles

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Get the user selected file path
% Parameters:   None
% Return Value: files - Nx1 cell containing all the files' path inside the
%                       directory user selected

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

function files = getFiles ()
    [file_name, path] = uigetfile(...
        {'*.txt; *.csv;', 'Files(*.txt, *.csv)'}, "MultiSelect","on");

    % If no files are selected
    if isequal(file_name, 0)
        files = {};
        return
    end

    files = fullfile(path, file_name);

    % If files return a character, turn it into a cell
    % This happens when user only selects one file
    if iscell(files) 
       files = files';
    else
        files = {files};
    end
end