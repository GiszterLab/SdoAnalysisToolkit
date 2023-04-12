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
%       {'sin'/'default'}
%       Method of breaking up colors; 
%           - 'sin' = Manipulate R/G/B channels by rotating 3 sinusoids at
%               a set phase to each other. 
%           - 'default' = Use MATLAB default color scheme (useful for when
%           the indexed order of the color may not match color on plot). 
%       xShift
%           [1x3] Doubles array, each element indexed [-2pi, 2pi]. Sets the
%           initial phase of the RGB sinusoids. 
%           - Default = [0,0,0]
%               

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [cArray] = rgb_colorGen(N_COLORS, method, xShift)
%xShift used to cycle indices/ set phase
if ~exist('method', 'var')
    method = 'sin'; 
end
if ~exist('xShift', 'var')
    switch method
        case 'sin'
            xShift = [0,0,0]; 
        case {'default', 'linear'}
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
        %prior to 2019b. 
        
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
        
end

%// DEMO (temp); 
%{
figure; 
for b=1:N_BINS
    line([1,2], [b,b], 'color', cArray(b,:)); 
end
%} 
end