% A color-mapping function for plotting the SDO matrix which sets the 0
% components to a standard white/translucent

% Because the negative components are always >= magnitude of (+), there
% needs to be a scale warping to result with zeros where expected. 

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


function [cMap] =  getSdoColormap(sMat, nColors)
if ~exist('sMat', 'var')
    sMat = 0.1*ones(10)-eye(10); % dummy 0-1;
end
if ~exist('nColors', 'var')
    nColors = 256; 
end

% __ Find minimum and maximum values of provided SDO matrix to
% appropriately warp the colors around 0; 
cMax = max(sMat,[],"all"); 
cMin = min(sMat,[], "all"); 

if cMax == cMin % all empty or zero/equal
    cMap = ones(nColors,3); 
    return; 
end


cWidth = (cMax-cMin)/(nColors-1);

cV = cMin:cWidth:cMax; 

zI = find( (cV > -cWidth)& (cV < cWidth)); % nearest zero val; 
if length(zI) > 1
    [~, I] = min( cV(zI)); 
    zI = zI(I);  
elseif isempty(zI)
    [~,zI] = min(abs(cV)); 
end

% __ count number of iterations we want to make (smooth)
nNeg = (zI-1); 
nPos = (nColors-zI); 


% ___ Seed with the semi-heatmap SDO (blue --> Orange)
%hList = {'#008d7f', '#11988a', '#22a394', '#33af9f', '#44baa9', '#55c5b4', '#77d1c3', '#99dcd2', '#bbe8e1', '#ddf3f0', '#ffffff', '#efd3c5', '#eeb59a', '#ec976e', '#ea8150', '#e66d38', '#e35a21', '#e45b16', '#ed8625', '#f6b135', '#ffdc44'}; 
%hList = {'#008d7f', '#209889', '#36a394', '#4caea0', '#62baac', '#79c5b8', '#91d1c5', '#aaddd3', '#c5e8e1', '#e1f4f0', '#ffffff', '#edd5ca', '#e8baa7', '#e2a388', '#de916e', '#db8459', '#db7e4a', '#de8041', '#e58c41', '#f0a34a', '#ffc65f'}; 
%hList = {'#008d7f', '#1a9e8f', '#33af9f', '#4dbfaf', '#67cebe', '#82dbcc', '#9de8da', '#b7f2e7', '#cff7ef', '#e7fbf7', '#ffffff', '#f7f0e8', '#fcf0de', '#ffe4cc', '#feceb2', '#feb897', '#e4835d', '#cb4e23', '#cb5113', '#e58b2e', '#ffc549'}; 

%hList = {'#008d7f', '#289d8e', '#42ad9d', '#5abbac', '#72c9ba', '#89d6c8', '#a1e1d5', '#b9ebe1', '#d1f3ec', '#e8faf6', '#ffffff', '#ede9e7', '#eee0da', '#f1d4c7', '#f7c7b1', '#feb897', '#ed9066', '#e37e47', '#e38137', '#ec9937', '#ffc549'}; 
%hList = {'#078d95', '#1b9b9d', '#2ea9a5', '#42b7ac', '#55c5b4', '#69cfbd', '#7cd8c6', '#90e2cf', '#a4ebd7', '#bbf0e1', '#d1f5eb', '#e8faf5', '#ffffff', '#fcddd7', '#fac8af', '#f7b387', '#eba277', '#e09166', '#d57f55', '#ca6139', '#bf421c', '#b52400', '#ce5918', '#e68f31', '#ffc549'}; 
%hList = {'#247ab2', '#2184a6', '#1f8d9a', '#1d968e', '#1b9f83', '#2bab8f', '#3bb69a', '#4bc1a6', '#5bcdb2', '#84d9c5', '#ade6d9', '#d6f2ec', '#ffffff', '#f8dfdc', '#f2cbb9', '#ebb796', '#e6a37e', '#e18f65', '#db7c4c', '#cf5e33', '#c24119', '#b52400', '#ce601f', '#e69d3e', '#ffda5e'}; 
hList = {'#298da0', '#1f91a0', '#1596a0', '#0a9ba1', '#00a0a1', '#12aba9', '#23b7b1', '#35c2ba', '#46cdc2', '#74dad1', '#a3e6e1', '#d1f3f0', '#ffffff', '#f2e6df', '#edd5c7', '#e9c5af', '#e4ad8e', '#e0946d', '#db7c4c', '#ce6035', '#c0441d', '#b22905', '#cc6423', '#e59f40', '#ffda5e'}; 

sMap = rgb_from_hexlist(hList); 

%{
% ___ This is the un-warped colormap; 
sMap= [ ...
[0.000, 0.553, 	0.498];
[0.208,	0.596, 	0.545];
[0.318, 0.643, 	0.592];
[0.412, 0.686, 	0.643];
[0.502, 0.729, 	0.690];
[0.584, 0.776, 	0.741];
[0.671, 0.820,  0.792];
[0.753, 0.863, 	0.843];
[0.835, 0.910, 	0.894];
[0.918, 0.953, 	0.945];
[1.000, 1.000,  1.000]; 
[0.976, 0.855, 	0.765];
[0.988, 0.741,  0.557];
[0.980, 0.627, 	0.376];
[0.910, 0.533, 	0.286];
[0.843, 0.439,	0.196];
[0.776, 0.341, 	0.106];
[0.690, 0.259, 	0.078];
[0.600, 0.176, 	0.051];
[0.510, 0.090, 	0.027];
[0.411, 0.000, 	0.000] ]; 
%}

sLen = ceil((size(sMap,1)-1)/2); 

nColors2 = nColors/2; 

warpSMap = ones(nColors,3); 
for d = 1:3
    dt = nColors2/sLen; % ratio of sampling points for provided vs. sampled colormap

    negV = 1:dt:nColors2+dt; % simulated points; 
    nV = 1:nColors2/nNeg:nColors2; 
    if ~(length(nV) == nNeg)
        nV = 1:nColors2/(nNeg+1):nColors2; 
    end
    d_neg = interp1(negV, sMap(1:sLen+1, d), nV); 
    posV = 1:dt:nColors2+dt; 
    pV = 1:nColors2/nPos:nColors2; 
    if ~(length(pV)== nPos)
        pV = 1:nColors2/(nPos+1):nColors2; 
    end
    if mod(length(sMap),2)== 0
        d_pos = interp1(posV, sMap(sLen:end,d), pV); 
    else
        d_pos = interp1(posV, sMap(sLen+1:end,d),pV); 
    end
    warpSMap(1:nNeg,d)  = d_neg; 
    warpSMap(zI+1:end,d)= d_pos; 
end

cMap = warpSMap; 

%{
colormap(warpSMap); 
1; 
dx_neg = ([1,1,1]-maxNegCol)/nNeg; 
dx_pos = (maxPosCol-[1,1,1])/nPos; 
%

% Saturation sweep; 

%
maxNegCol = [0.314, 0.894, 0.827]; 
maxPosCol = [0.968, 0.498, 0.129]; 

parMap = parula; % Get the nonlinear fitting; 

rectPar = ones(256,3); 

for d = 1:3
    nV = 1:nNeg/128:nNeg; 
    d_neg = interp1(nV, parMap(1:length(nV),d), 1:nNeg); 
    pV = 1:nPos/128:nPos; 
    d_pos = interp1(pV, parMap(256-length(pV)+1:256,d), 1:nPos); 
    rectPar(1:nNeg,d) = d_neg; 
    rectPar(zI+1:end,d) = d_pos; 
end
rectPar(isnan(rectPar)) = 1; 


xv_neg = [1:nNeg]'*dx_neg + ones(1,nNeg)'*maxNegCol; 
xv_pos = [1:nPos]'*dx_pos + ones(nPos,3); 

cMap = [xv_neg; [1,1,1]; xv_pos]; 
%}



end

function [colArr] = rgb_from_hexlist(hList)
% reads in Hex color strings, and converts to [0-1] RGB; 
nElem = length(hList); 

colArr = zeros(nElem, 3); 

for el = 1:nElem
    colArr(el,:) = hex2rgb(hList{el},1); 
end

end
