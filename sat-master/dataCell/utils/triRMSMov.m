function fxt = triRMSmov(xt, nPoints)
% Hybrid Triangular-weighted RMS Filter
% 
% Define a window +/- nPoints/2 the reference point. Square all values
% within the window, and weight these via a triangular weighting vector,
% with a peak on the original time value. Take the root of the mean of the
% weighted-squares. Output is zero-phase. 
%
% Designed for preprocessing 2kHz EMG data prior to ICA, as in
% Hart & Giszter, 2004
%
% INPUTS: 
% xt     - [N_CHANNELS x N_OBSERVATIONS] array of row vectors; 
% nPoints - The size of the window to weight. Points nPoints/2 on either
%      side of the reference point will be used. 
%
% OUTPUTS: 
% fxt   - [N_CHANNELS x N_OBSERVATIONS] array of filtered row vector data.

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

%_________________________________________________________________________

%/ triangular weighting vector; 
wvec=floor([1:nPoints/2 nPoints/2:-1:1]);

[sz_y,sz_x] = size(xt); % assume row major; 

[a,b] = meshgrid(1:nPoints, (0:sz_x-1)-floor(nPoints/4)); 
idx = a+b;
idx(idx<1) = 1; 
idx(idx>sz_x) = sz_x; 

wvect_2 = (wvec/sum(wvec.^2)); 

fxt = zeros(size(xt)); 

for d = 1:sz_y 
    z = xt(d,idx); 
    % This can be broken up into steps, but it all-in-one here for
    % speed; 
    fxt(d,:) = (mean((z(idx).^2)*diag(wvect_2),2)).^0.5'; 
end


end