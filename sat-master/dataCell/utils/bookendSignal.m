%% bookendSignal
% (Non-normalized Nomeclature). Method to extend a signal by a given
% distance, using a reflected portion of the data. 
%
% Used to extend signal without overly affecting the long-point mAVG
% filters. 
%
% sig = [1xN] array to filter. 
% N_POINTS = length of extension. 
% TYPE  = [1/2] 
%       - Type 1 = Pad signal w/ mean
%       - Type 2 = Pad signal w/ reflected signal points; 


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

function [bk_sig] = bookendSignal(sig, N_POINTS, TYPE)

if ~exist('CLASS', 'var')
    TYPE = 1; 
end

[sig_y, sig_x] = size(sig); 
if (sig_y > 1) && (sig_x == 1)
    TRANSPOSE = 1; 
    sig = sig'; 
else
    TRANSPOSE = 0; 
end

    sigLen = length(sig); 

    switch TYPE
        case 1 
            % ___ Mean-Pad
            mn_sig = mean(sig); 
            bk_sig = [mn_sig*ones(1,N_POINTS) sig mn_sig*ones(1,N_POINTS)]; 
        case 2
            % ___ Mirror-Pad
            if sigLen > N_POINTS
                bk_sig = [fliplr(sig(1:N_POINTS)) sig fliplr(sig(end-N_POINTS:end))]; 
            else
                sigLen = length(sig); 
                bk_sig = zeros(1, 2*N_POINTS+sigLen); 
                t0 = N_POINTS -sigLen; 
                bk_sig(1, t0+1:N_POINTS) = fliplr(sig); 
                bk_sig(1, N_POINTS+1:N_POINTS+sigLen) = sig; 
                bk_sig(1, N_POINTS+sigLen+1:N_POINTS+2*sigLen) = fliplr(sig); 
            end
    end

    if TRANSPOSE
        bk_sig = bk_sig'; 
    end

end