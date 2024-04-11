% common plotter for the spike-triggered 

% Only for use with the newer components of the parameter validation. 

%Breakout from existing functions; 

%Here, we passively pass most of the parameters, and hence this is not an
%ideal component for the end user; better to call only from the core method

% stapxt == A [ N_STATES x N_OBS] method w/ p(x,t)

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

function f =  stirpd(stapxt, N_X0_TBINS, vars)
arguments
    stapxt
    N_X0_TBINS {mustBeInteger} = size(stapxt,2); 
    vars.nSpikes  = 0; 
    vars.binDuraMs = []; 
    vars.titleStr = []; 
end
N_OBS = vars.nSpikes; 
%{
if ~iscell(stapxt)
    stapxt = {stapxt}; 
end
%}


[N_STATES, N_X0X1_TBINS] = size(stapxt); 
N_X1_TBINS = N_X0X1_TBINS-N_X0_TBINS; 

%// Here, we assume that the input is already maximally defined 

   f = figure; 

  % N_ELEM = length(stapxt); 
    
    %__ Mean State (STA in state space)
    scm = diag(1:N_STATES); 
    mnX = sum(scm*stapxt); 

    imagesc(stapxt); 
    %// conform plot
    axis([1, N_X0X1_TBINS, 1, N_STATES]); 
    axis xy
    line([N_X0_TBINS+0.5, N_X0_TBINS+0.5], [1,N_STATES], 'Color', 'r'); 
    hold on; 
    plot(mnX, 'color', 'blue', 'LineStyle','--', 'lineWidth', 1.5); 

    if ~isempty(vars.binDuraMs)
        TBIN_PERIOD = vars.binDuraMs; 
        %// set axes + ticks to whole numbers;
        x0Intrvl    = N_X0_TBINS*TBIN_PERIOD; 
        x1Intrvl    = N_X1_TBINS*TBIN_PERIOD; 
        x0_xticks0   = (1:x0Intrvl)/TBIN_PERIOD;
        x0_xticks   = [x0_xticks0 N_X0_TBINS]; %ensure spiketime is included;
        x0_xticks   = unique(x0_xticks); 
        x1_xticks   = (1:x1Intrvl)/TBIN_PERIOD+N_X0_TBINS; 
        xtks        = [x0_xticks x1_xticks]; 
        xtk_lbls    = (xtks-N_X0_TBINS)*TBIN_PERIOD;
        set(gca, 'XTick', xtks, 'XTickLabel', xtk_lbls)
        xticks(xtks);
        xlabel("Time relative to Spike (ms)")
    else
        %// Try to provide something which looks reasonable 
        xtks = xticks; 
        xticklabels(xtks - N_X0_TBINS); 
        xlabel("Time Bins relative to Spike")
    end
    ylabel("X(t)"); 
    %{
    if BY_STATE
        text(N_X0X1_TBINS-2.5, 2, strcat("N=", num2str(hcS(zz))), 'Color', [1,1,1]); 
        title(strcat("STA-P(x,t): x(s)=", num2str(zVals(zz)))); 
    else
    %}
        text(N_X0X1_TBINS-2.5, 2, strcat("N=", num2str(N_OBS)), 'Color', [1,1,1]); 
        if isempty(vars.titleStr)
            title("STA-P(x,t)"); 
        else
            title(vars.titleStr); 
        end
    %end
    colormap bone
    colorbar; 
end