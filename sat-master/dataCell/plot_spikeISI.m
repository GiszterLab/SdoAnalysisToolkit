%% sta-plot scratch
% Generic Method to plot the interspike interval (ISI) from the 'SpikeTimeCell'
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

function plot_spikeISI(spikeTimeCell, useTrials, useUnits, vars)
arguments
    spikeTimeCell
    useTrials   = 1:size(spikeTimeCell,2);
    useUnits    = 1:length(spikeTimeCell{1,1}); 
    vars.useField = 'times';
    vars.type  {mustBeMember(vars.type, {'linear', 'log'})} = 'linear'; 
    %vars.edges  = {'auto', 'common'
end

%PPFIELD = 'times'; 
PPFIELD = vars.useField; 
N_UNITS = length(useUnits); 
N_TRIALS = length(useTrials); 
if strcmp(vars.type, 'log')
    LOG_TRANSFORM = 1; 
else
    LOG_TRANSFORM = 0; 
end

%_____ Collect ISIs 

spkISICll = cell(N_TRIALS, N_UNITS); 
for tri=1:N_TRIALS
    tr = useTrials(tri); 
    for ui=1:N_UNITS
        u = useUnits(ui); 
         times = spikeTimeCell{1,tr}(u).(PPFIELD); 
         if length(times) > 1
             %// we can only calculate the ISI - between- spikes. 
            spkISICll{tri,ui} = diff(times); 
         end
    end
end

if (N_TRIALS) > 1 && (N_UNITS > 1)
    try
        spkCll = cellvcat(spkISICll); 
    catch
        spkCll = cellhcat(spkISICll')'; 
    end
else
    spkCll = spkISIcll; 
end

if isa(spkCll, 'double')
    spkCll = {spkCll}; 
end


nRows = ceil(sqrt(N_UNITS)); 
nCols = ceil(N_UNITS/nRows); 

%___________

figure;

for ui = 1:N_UNITS 
    subplot(nRows, nCols, ui); 
    u = useUnits(ui); 
    hold on; 
    nSpikes = length(spkCll{ui}); 
    if LOG_TRANSFORM == 1
        histogram( log(spkCll{ui})); 
        xMax = max(log(spkCll{ui})); 
    else
        histogram(spkCll{ui}); 
        xMax = max(spkCll{ui}); 
    end
    try
         title(spikeTimeCell{1,1}(u).sensor);        
    catch
        title(spikeTimeCell{1,1}(u).electrode); 
    end
    text(xMax/2, 0, strcat("N=",num2str(nSpikes))); 
end

if LOG_TRANSFORM
    suptitle2("Interspike Intervals (Log-Transformed)"); 
else
    suptitle2("Interspike Intervals"); 
end

end