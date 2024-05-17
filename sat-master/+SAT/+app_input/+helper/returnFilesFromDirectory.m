% Description:  Extract all the files inside a directory
% Parameters:   None
% Return Value: files - Nx1 cell containing all the files' path inside the
%                       directory user selected
function files = returnFilesFromDirectory ()
    pwd = "D:\PMK Files\Jobs\Research Cooridinator\Helper_Files_Python";

    % Catch the error if the user doesn't select any directory
    path = uigetdir(pwd); % Get the path for required directory
    % Get fiafafall the files inside the directory
    try file_struct = dir(path); 
    catch 
        return 
    end

    % Extract the xt files inside the table
    file_table = struct2table(file_struct);
    file_table.fullpath = fullfile(file_table.folder, file_table.name);
    files = file_table.fullpath(file_table.isdir == 0);
end