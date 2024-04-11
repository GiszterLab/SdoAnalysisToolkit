%% Resample X(t) to Specified Hz
% Macro to handle resampling time series data from sampling frequency 'FS' to
% desired frequency 'newFS'
%
% CONFORM = ensure xt max and xt min are preserved by resampling; clipping
% if necessary; 

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

function [rsXt] = resampleXtToHz(Xt, FS, newFS, CONFORM)
if ~exist('CONFORM', 'var')
    CONFORM = 0; 
end

% if an MxN Array, will perform columnwise; 

%// a bit more robust way of doing this; 

    decF = FS/newFS; 

    if ismembertol(decF,1)
        %// No change
        rsXt = Xt; 
    elseif ismembertol(decF, round(decF))
        %// decF is effectively an int; --> Normal Downsample
        if ~any(size(Xt) == 1) 
            %// array; 
            rsXt0 = decimate(Xt(:,1), round(decF)); 
            rsXt = zeros(length(rsXt0), size(Xt,2)); 
            for col = 1:size(rsXt,2)
                rsXt(:,col) = decimate(Xt(:,col), round(decF)); 
            end
        else
            %// single time series
            rsXt = decimate(Xt, round(decF));
        end
    elseif ismembertol(1/decF, round(1/decF))
        %// decF is rational --> Normal upsample
        if ~any(size(Xt) == 1)
            %// array; 
            rsXt0 = interp(Xt(:,1), round(1/decF));
            rsXt = zeros(length(rsXt0), size(Xt,2)); 
            for col = 1:size(rsXt,2)
                rsXt(:,col) = interp(Xt(:,col), round(1/decF)); 
            end
        else 
            rsXt = interp(Xt, round(1/decF));
        end
    else
        %// Non integer upsample/downsample. Two stages; 
        LC = lcm(FS, newFS); % least-common multiple of two Hz
        % 1) Upsample 
        upXt = interp(Xt, round(LC/FS)); 
        %upXt = interpolate(Xt, round(LC/FS)); 
        % 2) Downsample
        rsXt = decimate(upXt, round(LC/newFS));
    end

if CONFORM
    minX = min(Xt); 
    maxX = max(Xt); 
    %
    LI_MAX = rsXt > maxX; 
    rsXt(LI_MAX) = maxX; 
    LI_MIN = rsXt < minX; 
    rsXt(LI_MIN) = minX; 
end
    
    
end