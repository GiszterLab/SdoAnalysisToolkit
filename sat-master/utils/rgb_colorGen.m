%% rgb_colorGen
%
% A method used to generate a spectrum of RGB triplets, within range [0-1]. 
% Attempt to generate a color spectrum into N aesthetically pleasing
% elements for plotting
%
% INPUTS
%   - N_COLORS; 
%       [integer] The number of colors to produce
%   - method
%       {'sin'/'default', 'linear', 'polar'}
%       Method of breaking up colors; 
%           - 'sin' = Manipulate R/G/B channels by rotating 3 sinusoids at
%               a set phase to each other. 
%           - 'default' = Use MATLAB default color scheme (useful for when
%           the indexed order of the color may not match color on plot). 
%           - 'linear' = Linear interpolation from R-->G-->B
%           - 'polar', Red = Low values; Blue = High values
%       xShift
%           [1x3] Doubles array, each element indexed [-2pi, 2pi]. Sets the
%           initial phase of the RGB sinusoids. 
%           - Default = [0,0,0]
%               

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

function [cArray] = rgb_colorGen(N_COLORS, method, xShift)
%xShift used to cycle indices/ set phase
if ~exist('method', 'var')
    method = 'sin'; 
end
if ~exist('xShift', 'var')
    switch method
        case 'sin'
            xShift = [0,0,0]; 
        case {'default', 'linear', 'polar'}
            xShift = 0;
    end
end

switch method
    case 'sin'
        %// Triple-phase sinuoid for smooth-mapping RGB
        XRANGE = 1:N_COLORS; 

        phi_v = [pi/2, 0, pi/6] + xShift; 

        phiArr = repmat(phi_v, N_COLORS,1); 

        radRange = (XRANGE/N_COLORS)*pi/2; 

        radArr = repmat(radRange', 1, 3); 

        cArray = sin(radArr+phiArr); 

        cArray = abs(cArray); 
    
    case 'linear'
        %// Single Ramp-in/Ramp-out of R-->G-->B
        x0 = 256*2; 
        xR = [0:255, zeros(1,256)] / 256; 
        xG = [zeros(1,128), 0:255, zeros(1,128)] / 256; 
        xB = [zeros(1,255), 0:255]/ 256; 
        
        XRANGE = round(xShift+1:(x0-xShift)/N_COLORS:x0); 
        
        cArray = [xR(XRANGE)', xG(XRANGE)', xB(XRANGE)']; 
        
    case 'default'
        %// Used for recreating/restarting matlab default color scheme
        %prior to 2019b, or otherwise forcing 'default-like' coloring
        
        %// 7 Default colors; 
        colArr = [...
            [0      0.4470  0.7410]; ...
            [0.8500 0.3250  0.0980]; ...
            [0.9290 0.6940  0.1250]; ...
            [0.4940 0.1840  0.5560]; ...
            [0.4660 0.6740  0.1880]; ...
            [0.3010 0.7450  0.9330]; ...
            [0.6350 0.0780  0.1840] ]; 
        %
        lkup = 1:N_COLORS + round(xShift); 

        numIDX = mod(lkup,7); 
        numIDX(numIDX ==0) = 7; 
        cArray = colArr(numIDX,:); 

    case 'polar'
        %// Red --> Blue
        xR = [1, 2/255, 61/225]; %/ half red;  
        xB = [5/255, 120/225, 1]; %half-blue; 
        x1 = [1,1,1]; 
        
        isOdd = mod(N_COLORS,2) > 0;  
        
        N_ROWS = floor(N_COLORS/2); 
        
        dxR = (x1-xR)/(N_ROWS); 
        dxB = (xB-x1)/(N_ROWS);
        
        rMat = repmat(dxR, N_ROWS-1,1); 
        bMat = repmat(dxB, N_ROWS-1,1); 
        cLo = cumsum([xR;rMat]); 
        cHi = cumsum([x1;bMat]); 
        if isOdd
            cArray = [cLo; x1; cHi]; 
        else
            cArray = [cLo; cHi]; 
        end

        %{
        %// This is TOO DARK
        xR = [1,0,0]; 
        xB = [0,0,1]; 
        %N_COLORS
        dX = (xB-xR)/(N_COLORS/2); 
        dMat = repmat(dX, N_COLORS,1); 
        mat = repmat([1,0,-1], N_COLORS,1);
        cMat = cumsum(dMat); 
        tMat = cMat+mat;
        tMat(tMat <0) = 0; 
        tMat(tMat>1) = 1; 
        LI = (all(tMat==0, 2));  
        tMat(LI,:) = 1; 
        cArray = tMat; 
        %}

end

end