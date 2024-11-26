%% SAT - app_input:: 
%% helper.filterCharIndex


% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:      Remove the char/str row until only one is left in 'data' 
%                   and 'char_index', one is intentionally left to split into
%                   trials
% Parameters:       data - all the file data as cell 
%                   char_index - char_index resulting from the
%                                getTrialIndex() function on the data
%                   repeated_char_index - the first index in a pair where
%                                         repeated character starts
% Return Values:    data - modified data after removing some rows
%                   char_index - modified data after removing some index
% Use:              For filtering char/str rows in concatenated data
%                   ***** MAKE SURE YOU HAVE YOUR HEADER DATA FIRST BEFORE
%                   FILTERING ANY CELL *****
%                   *** Currenlty used in concatenated data only however,
%                   this can be use in any file type at all ***

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

function [data, char_index] = filterCharIndex (data, char_index, repeated_char_index)
arguments
    data (:,:) cell
    char_index (1,:) double {mustBePositive, mustBeInteger}
    repeated_char_index = char_index(diff(char_index) == 1);
end

    % Remove the duplicate and subtract accordingly
    for i = 1 : length(repeated_char_index)
        data(repeated_char_index(i) + 1, :) = []; % Remove the consecutive second row

        % Subtract accordingly for char_index and repeated_char_index
        remove_index = find(char_index == repeated_char_index(i)) + 1;
        char_index(remove_index) = [];
        char_index(remove_index : end) = char_index(remove_index : end) - 1;
        if i ~= length(repeated_char_index)
            repeated_char_index(i + 1 : end) = repeated_char_index(i + 1: end) - 1;
        end      
    end

    % Special Case: If there is Char/Str row at the last column
    if char_index(end) == height(data)
        data(end, :) = [];
        char_index(end) = [];
        
    end
end