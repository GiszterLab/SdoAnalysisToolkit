%% Normalize PDF Columns to Unity
% Common Macro for normalization
%
% Treat column vectors as discretely (and homogenously) sampled probability
% distribution functions. Elementwise division of each element by the sum
% of its column. 
%
% Because p(x) cannot equal zero, handle negative values of columns either
% by 1) treating x<0 as x = 0 or 2) 'leveling' = adding a scalar to the
% whole vector to make the most negative value == 0.
%
% 'handleNeg' (Optional) may be either 'level' or 'zero'

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


function [normpdf] = normpdfcol2unity(array, handleNeg)
%// Assume that the array contains col vectors representing probability
%density functions. Normalize colwise using vectors
    
%Handle Neg; (no part of PDF can be < 0)
    %'level' = translate PDF by |min|
    %'zero' = all < 0; --> 0
    %'none' = Not defined as a case; --> essentially uncorrected 

if nnz(any(array<0)>0) % note 'all' tag not valid with my version of MATLAB
    try 
        handleNeg; 
    catch
        handleNeg = 'level';
    end
    
    switch handleNeg
        case 'level'
            array = array+repmat(abs(min(array)), size(array,1),1); 
            %arr = arr+ abs(min(arr)); 
        case 'zero'
            array(array<0) = 0; 
    end
end

scalearr = repmat(sum(array), size(array,1), 1); 
normpdf = array./scalearr; 

normpdf(isnan(normpdf)) = 0; %flush NaNs to 0; 

end