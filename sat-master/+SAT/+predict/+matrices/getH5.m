%H5: Markov Operator; 

%_______________________________________
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

function [mat] = getH5(nStates, x0, nTimeBins, vars)
arguments
    nStates
    x0
    nTimeBins = size(nStates,1); % number of time bins forward for convolution. 
    vars.type {mustBeMember(vars.type, {'L', 'M'})} = 'L'; 
    vars.method {mustBeMember(vars.method, {'static', 'average'})} = 'static'; 
end

M = pxTools.getMarkovFromXt(x0, nStates); 

% __ The average distribution within the interval +1:+nTime bins = average
% of terminal matrices leading to this point; 
%

switch vars.method
    case 'static'
        %// Single Markov Prediction; DT forward in time; 
        % __>> This is the Markov as reported in the paper
        Mdt = M^nTimeBins; 
    case 'average'
        %// Take the average Markov over all time steps; 

        Mdt = zeros(nStates); 
        for t = 1:nTimeBins
            Mdt = Mdt+(M^t)/nTimeBins; 
        end
end
 
switch vars.type
    case 'M'
        mat = Mdt;  
    case 'L'
        %// Delta-Markov = expected change of state from intial
        mat = Mdt-diag(sum(Mdt)); 
end


end