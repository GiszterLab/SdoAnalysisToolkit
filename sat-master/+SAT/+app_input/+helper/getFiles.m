% Description:  Get the user selected file path
% Parameters:   None
% Return Value: files - Nx1 cell containing all the files' path inside the
%                       directory user selected
function files = getFiles ()
    [file_name, path] = uigetfile(...
        {'*.txt; *.csv;', 'Files(*.txt, *.csv)'}, "MultiSelect","on");

    % If no files are selected
    if isequal(file_name, 0)
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