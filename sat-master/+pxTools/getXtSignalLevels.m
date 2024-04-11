% Derive a vector of edges describing the relationship between signal
% amplitude and bins. 
%// Modular method of assigment
%
%

% To avoid porducing 'NaN' for ranging values, signal values greater than
% the defined discretization range willl be assigned to the closest defined
% value (i.e. clipping). 
% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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

function signalLevels=getXtSignalLevels(X_MAX,X_MIN,N_BINS,XT_MAP_MODE)

esf = 1e-6; 

switch XT_MAP_MODE
    case 'linear'
        signalLevels = linspace(X_MIN, X_MAX, N_BINS+1);
    case 'log'
       min_y=log(max(X_MIN,esf));% if min_x<0.001 we set it to 0.001
       max_y=log(X_MAX);
       signalLevels = exp(linspace(min_y, max_y, N_BINS+1)); 
       
    case 'linearsigned'
        %// modification to permit negative values;
        absMax = max(abs([X_MAX, X_MIN])); 
        nStep = absMax/(N_BINS/2); 
        signalLevels = -absMax:nStep:absMax; 
       
    case 'logsigned'
       %// modification to permit negative values; 
       absMax   = max(abs([X_MAX, X_MIN])); 
       LAbsMax  = log(absMax); 
       LNStep   = LAbsMax/(N_BINS/2); 
       sigHalfLevels = exp(LNStep:LNStep:LAbsMax); 
       signalLevels = [-fliplr(sigHalfLevels), 0, sigHalfLevels];
end

end