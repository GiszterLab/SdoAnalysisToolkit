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