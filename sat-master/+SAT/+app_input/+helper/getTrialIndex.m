%% SAT - app_input:: 
%% helper.getTrialIndex

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