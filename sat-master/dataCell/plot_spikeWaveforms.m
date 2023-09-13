%% plot SpikeWaveforms
% Generic Method to plot the spikeWaves from the 'SpikeTimeCell'
%
% --> Also called as a method for ppDataCell
% --> Future stability upgrades will be needed. 

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

function plot_spikeWaveforms(spikeTimeCell, useTrials, useUnits, PLOT_ALL, vars)
arguments
    spikeTimeCell
    useTrials   = 1:size(spikeTimeCell,2);
    useUnits    = 1:length(spikeTimeCell{1,1}); 
    PLOT_ALL    = 0; 
    vars.useField = 'envelope'; 
end

PPFIELD = vars.useField; 
N_UNITS = length(useUnits); 
N_TRIALS = length(useTrials); 

spkWvCll = cell(N_TRIALS, N_UNITS); 
for tri=1:N_TRIALS
    tr = useTrials(tri); 
    for ui=1:N_UNITS
        u = useUnits(ui); 
        spkWvCll{tri,ui} = spikeTimeCell{1,tr}(u).(PPFIELD); 
    end
end

if N_TRIALS > 1
    spkCll = cellvcat(spkWvCll); 
else
    spkCll = spkWvCll; 
end

nRows = ceil(sqrt(N_UNITS)); 
nCols = ceil(N_UNITS/nRows); 

figure;

for ui = 1:N_UNITS
    subplot(nRows, nCols, ui); 
    u = useUnits(ui); 
    hold on; 
    if PLOT_ALL == 1
        plot(spkCll{ui}', 'color', [0.36,0.36,0.45, 0.1]); %gray/teal
    else
        spkStd  = std(spkCll{ui},[],1); 
        spkMn   = mean(spkCll{ui},1); 
        
        spkLen = length(spkMn); 
        spkXX = [1:spkLen spkLen:-1:1]; 
        %spkXX = [1:52 52:-1:1]; %standard NEV 52-pt; 
        spkYY = [spkMn+spkStd fliplr(spkMn-spkStd)]; 
        %
        spkP = polyshape(spkXX, spkYY, 'Simplify', false); 
        plot(spkP, 'faceColor', [0.36,0.36,0.45, 0.1]);
    end 
    plot(mean(spkCll{ui}), 'color', [0.1,0.1,0.1, 1], 'lineWidth', 1.5); 
    axis([1, spkLen, -inf, inf]); 
    try
         title(spikeTimeCell{1,1}(u).sensor);        
    catch
        title(spikeTimeCell{1,1}(u).electrode); 
    end
    text(spkLen, 0, strcat("N=", num2str(size(spkCll{ui},1)))); 
end

end