%% DEMO V2.

% Copyright (C) 2024 Trevor S. Smith
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

REGEN = 1; % Flag, [0,1]

if (REGEN == 1) || ~exist('sat', 'var')
    % utilize the V2 classes; 
    xtdc2  = xtDataCell2(); 
    xtdc2.import(xtData); 

    ppdc2 = ppDataCell2(); 
    ppdc2.import(ppData); 

    sat = SAT.analyzer(); % Generate the new analysis class (V2)
    sat.import(xtdc2,ppdc2); % pull in new data; 

    sat.compute(); 
end

% // Demonstrate plotters
% --> These can be whatever range you are interested in
XT_CH_NO = 6; % VE-EMG
PP_CH_NO = 4; % Interneuron


sat.plot(XT_CH_NO, PP_CH_NO); % Draw the plot