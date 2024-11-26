%% SAT - app_input :: 
%% determinePpFileType

% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Return a pp_cell when a user inputs PP files
% Parameter:    None
% Return Value: pp_cell - Nx1 cell array where each row contains Mx2 cell for
%                         each trial (N = Trials, M = No. of Sensors)
% Note:         -I am expecting a json-style header at the first row
%               -Json-style header = {"Sensor Name" : 1, "Sensor Name" :
%               32, ....}
%               -A trial header can be anything as long as it's a character or
%               string
%               *** A user can input multiple PP files representing each trial 
%               as long as there is a json-formatted header on one of them. 
%               A use can input concatenated pp file, however
%               concatenated file must always be input as ONE only. ***

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

function pp_cell = determinePpFileType ()
arguments(Output)
    pp_cell (:,1) cell
end
    % Get the files
    files = SAT.app_input.helper.getFiles();
    % if the user inputted nothing
    if isempty(files)
        pp_cell = cell.empty(0,1);
        return
    end
    
    if height(files) == 1 % If only one file exists 
        % Get the header from the first line of pp file
        fid = fopen(files{1,1});
        header_line = fgetl(fid);
        fclose(fid);
        
        % Confirm there is a correct header for PP
        try
            pp_header_struct = jsondecode(header_line); % Structure for original pp data
            % pp_sensors = fields(pp_header_struct); % Sensor Names
        catch
            error("!!! WHERE IS HEADER? !!!")
        end
    
        % Use readcell to read the concatenated file
        pp_data = readcell(files{1,1});
        
        % Find the character index for 'trial' char
        % char_index will never be empty as it will always contain the header
        char_index = SAT.app_input.helper.getTrialIndex(pp_data, 1000);
    
        if any(diff(char_index) > 1) % Concatenated file
            [pp_data, char_index] = SAT.app_input.helper.filterCharIndex(pp_data, char_index);
            % Take only the first and second column for pp_data
            % (cell2mat() won't work when there are missing values)
            pp_data = pp_data(:,1:2);
            pp_cell = SAT.app_input.getPpDataFromConcatenatedFile(pp_data, char_index, pp_header_struct);
        else % Normal file
            pp_cell = SAT.app_input.getPpDataFromDirectory(files);
        end
    
    else % More than one file
        pp_cell = SAT.app_input.getPpDataFromDirectory(files);
    end
end