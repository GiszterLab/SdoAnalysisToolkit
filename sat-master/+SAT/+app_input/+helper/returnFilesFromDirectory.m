%% SAT - app_input:: 
%% helper.returnFilesFromDirectory

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Extract all the files inside a directory
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


function files = returnFilesFromDirectory ()
    %pwd = "D:\PMK Files\Jobs\Research Cooridinator\Helper_Files_Python"; 
    % Catch the error if the user doesn't select any directory
    path = uigetdir(pwd); % Get the path for required directory
    % Get all the files inside the directory
    try file_struct = dir(path); 
    catch 
        return 
    end

    % Extract the xt files inside the table
    file_table = struct2table(file_struct);
    file_table.fullpath = fullfile(file_table.folder, file_table.name);
    files = file_table.fullpath(file_table.isdir == 0);
end