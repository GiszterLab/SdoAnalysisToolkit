% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Return the index numbers of rows that has nothing but
%               char/string inside it
% Parameters:   data - a 2D cell array
%               trial_limit - The amount of trials for allocation
% Return Value: char_index - (1xN double) index numbers of rows that have
%                             char/string
% Use:          In concatenated XT/PP file
% Note:         *** Make sure to check 
%               whether the return value is empty after returning ***

function char_index = getTrialIndex(data, trial_limit)
arguments
    data (:,:) cell
    trial_limit (1,1) double {mustBePositive, mustBeInteger} = 1000
end

    % Find the character index for 'trial' char
    char_index = zeros(1, trial_limit);
    counter = 1;
    for i = 1 : height(data)
        % If the data is a character, then this is the row 
        % where 'trial' is written
        if ischar(data{i,1})
            char_index(counter) = i;
            counter = counter + 1;
        end
    end
    char_index = char_index(char_index ~= 0);
end