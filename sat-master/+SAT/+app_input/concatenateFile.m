%% SAT - app_input:: 
%% concatenateFile

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Transferring multiple XT/PP files into one single concatenated file
%               If input as 1, it will create "xt.csv"
%               If input as 2, it will create "pp.csv"
% Parameter:    file_type - Accept integer values of 1 or 2
%                           1 refers to xt directory
%                           2 refers to pp directory
% Return Value: None
%               However, it will create a new csv file


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

function concatenateFile(file_type)
arguments
    file_type {mustBeOneOrTwo} = 1
end
    
    % Get files' names
    try files = SAT.app_input.helper.getFiles();
    catch
        return
    end

    % Check what type of file the user selected
    if file_type == 1
        filename = "xt.csv";
    elseif file_type == 2
        filename = "pp.csv";
    end

    % Delete the file if it already existed
    if isfile(filename)
        delete(filename);
    end

    trial_no = 1; 
    % Loop through all the files
    for i = 1 : length(files)
        % Write Header
        if i == 1
            if file_type == 1 % XT
                % Get the header as cell
                opts = detectImportOptions(files{i});
                old_header_cell = opts.VariableNames;
                writecell(old_header_cell, "xt.csv", "Delimiter", ',', ...
                    "WriteMode", "append");

            elseif file_type == 2 % PP
                % Get the 1st line of header
                fid = fopen(files{i});
                header_line = fgetl(fid);
                fclose(fid);

                % Write the header line
                writelines(header_line, filename, "WriteMode", "append");
            end
        end

        % Check if all the headers for XT Files are the same
        if file_type == 1 && i > 1 % XT
            opts = detectImportOptions(files{i});
            current_header_cell = opts.VariableNames;
            if ~SAT.app_input.helper.checkColumns(old_header_cell, current_header_cell)
                error("!!!You don't have the same header at TRIAL %03d compared to the previous trials!!!", ...
                    trial_no);
            end
            old_header_cell = current_header_cell;
        end

        % I am not checking if all the headers of pp are the same since
        % I don't expect the user to manually write all the headers in
        % each file

        % Write Trial String
        write_string = sprintf('Trial_%03d', trial_no);
        writelines(write_string, filename, "WriteMode", "append");
        trial_no = trial_no + 1;

        % Write Matrix Data
        matrix_data = readmatrix(files{i});
        writematrix(matrix_data, filename, "WriteMode", "append");
    end
end

% Argument function
function mustBeOneOrTwo(x)
    if ~(x == 1 || x == 2)
        error("Value must be the interger value of 1(XT) or 2(PP).")
    end
end