%% bookendSignal
% (Non-normalized Nomeclature). Method to extend a signal by a given
% distance, using a reflected portion of the data. 
%
% Used to extend signal without overly affecting the long-point mAVG
% filters. 
%
% sig = [N_CHANNNELS x N_OBSERVATIONS] array to filter. 
% N_POINTS = length of extension. 
% TYPE  = [1/2] 
%       - Type 1 = Pad signal w/ mean
%       - Type 2 = Pad signal w/ reflected signal points; 

% 10.23.2024 - Fixed bug for [MxN] arrays

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

if ~exist('TYPE', 'var')
    TYPE = 1; 
end

[sig_y, sig_x] = size(sig); 
if (sig_y > 1) && (sig_x == 1)
    TRANSPOSE = 1; 
    sig = sig'; 
    [sig_y, sig_x] = size(sig); 
else
    TRANSPOSE = 0; 
end

    sigLen = length(sig); 

    switch TYPE
        case 1 
            % ___ Mean-Pad
            mn_sig = mean(sig,2); 
            bk_sig = [mn_sig*ones(sig_y,N_POINTS) sig mn_sig*ones(sig_y,N_POINTS)]; 
        case 2
            % ___ Mirror-Pad
            if sigLen > N_POINTS
                bk_sig = [fliplr(sig(:,1:N_POINTS)) sig fliplr(sig(:,end-N_POINTS+1:end))]; 
            else
                sigLen = length(sig); 
                bk_sig = zeros(sig_y, 2*N_POINTS+sigLen); 
                t0 = N_POINTS -sigLen; 
                bk_sig(:, t0+1:N_POINTS) = fliplr(sig); 
                bk_sig(:, N_POINTS+1:N_POINTS+sigLen) = sig; 
                bk_sig(:, N_POINTS+sigLen+1:N_POINTS+2*sigLen) = fliplr(sig); 
            end
        case 3
            % __ Slope Project 
            1; 
            dx0 = mean(diff(sig(:,1:N_POINTS)), 'omitnan'); 
            dx1 = mean(diff(sig(:,end-N_POINTS:end)), 'omitnan'); 
            C0 = diag(dx0)*ones(sig_y, N_POINTS); 
            C1 = diag(dx1)*ones(sig_y, N_POINTS); 
            pad0 = (cumsum(C0,2)); 
            pad1 = (cumsum(C1,2)); 
            % Project and level; 
            pad0_0 = pad0+dx0-pad0(:,end)+sig(:,1); 
            pad1_1 = pad1-dx0+sig(:,end); 
            bk_sig = [pad0_0 sig pad1_1]; 
            %bk_sig = [pad0+sig(:,1), sig, pad1+sig(:,end)]; 
            1; 

    end

    if TRANSPOSE
        bk_sig = bk_sig'; 
    end

end