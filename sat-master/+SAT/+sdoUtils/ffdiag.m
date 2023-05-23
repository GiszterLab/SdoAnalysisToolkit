%% diagonal filter
%// Apply a zero-order filter ('filtfilt' to each matrix diagonal of a
% (SDO) matrix, smoothing motifs for interpretation.
% Optionally maintains linearity of SDO matrix using post-hoc conform. 
%
% Input matrix is 'sheared' to align diagonals to rows, then filtered using
% 'filtfilt' to apply zero-phase filtering, then restored to the orignal
% matrix. 
%
% If paired with 'conform' flag, will post-hoc ensure SDO maintains
% linearity. If a kernel is not passed to the filter, will use a gaussian
% filter. 

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

function [fArr] = ffdiag(b, a, arr, CONFORM)
if ~exist('CONFORM', 'var')
    CONFORM = 0; 
end
if isempty(b)
    %// Use a gaussian filter here
    b = getgausskernel(1,1); 
end
if isempty(a)
    a = 1; 
end

N_DIAGS = size(arr,2); 

shearArr = zeros(2*N_DIAGS-1, N_DIAGS); 
t0 = N_DIAGS; 
t1 = 2*N_DIAGS-1; 

for d = 1:N_DIAGS
   shearArr(t0:t1,d) = arr(:,d); 
   t0 = t0-1; 
   t1 = t1-1; 
end

%// Apply Filter

fShear = filtfilt(b, 1, shearArr')';

%// 'Unshear' Array; 

fArr = zeros(N_DIAGS); 

t0 = N_DIAGS; 
t1 = 2*N_DIAGS-1; 
for d = 1:N_DIAGS
    fArr(:,d) = fShear(t0:t1,d); 
    t0 = t0 -1; 
    t1 = t1-1; 
end

%// Back-Ensure SDO is set

if CONFORM
    fArr = SAT.sdoUtils.conformsdo(fArr); 
end
    

end
    
%{
figure;
subplot(1,2,1)
imagesc(arr); 
subplot(1,2,2); 
imagesc(fArr2); 
%}
%for d=1:N_DIAG
%    dSig = diag(
