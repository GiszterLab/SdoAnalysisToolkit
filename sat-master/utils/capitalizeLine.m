%% capCaseLine 
% utility macro from 
% string/char switch macro for capitalizing the first term

% Copyright (C) 2023 Trevor S. Smith
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


function [lineOut] = capitalizeLine(lineIn)

% --> Need to switch between Char and String typecasing

typ = class(lineIn); 

switch typ
    case 'string'
        %// need to split substring; 
        s0 = extractBefore(lineIn,2); 
        s1 = extractAfter(lineIn,2); 
        
        lineOut = strcat(upper(s0), s1); 
        
    case 'char'
        s0 = lineIn(1); 
        s1 = lineIn(2:end); 
        
        lineOut = [upper(s0) s1]; 
end

end