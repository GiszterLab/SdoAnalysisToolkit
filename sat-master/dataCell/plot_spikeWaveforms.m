%% sta-plot scratch
%// Generic Method to plot the spikeWaves from the 'SpikeTimeCell'
%// Can be useful for convincing others about the validity of the spike
%sorting; 
% --> Also called as a method for ppDataCell
% --> Future stability upgrades will be needed. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function plot_spikeWaveforms(spikeTimeCell, useTrials, useUnits, PLOT_ALL, PPFIELD)
if ~exist('useTrials', 'var')
    useTrials = []; 
end
if ~exist('useUnits', 'var')
    useUnits = []; 
    %useUnits = length(spikeTimeCell{1,1}); 
end
if ~exist('PLOT_ALL', 'var')
    PLOT_ALL = 0;
end
if ~exist('PPFIELD', 'var')
    PPFIELD = []; 
end
if isempty(useUnits)
    useUnits = 1:length(spikeTimeCell{1,1});
end
if isempty(useTrials)
    useTrials = size(spikeTimeCell,2); 
end
if isempty(PPFIELD)
    PPFIELD = 'envelope'; 
end

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

spkCll = cellvcat(spkWvCll); 

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
        spkXX = [1:52 52:-1:1]; 
        spkYY = [spkMn+spkStd fliplr(spkMn-spkStd)]; 
        %
        spkP = polyshape(spkXX, spkYY, 'Simplify', false); 
        plot(spkP, 'faceColor', [0.36,0.36,0.45, 0.1]);
    end 
    plot(mean(spkCll{ui}), 'color', [0.1,0.1,0.1, 1], 'lineWidth', 1.5); 
    axis([1, 52, -inf, inf]); 
    title(spikeTimeCell{1,1}(u).electrode); 
    text(52, 0, strcat("N=", num2str(size(spkCll{ui},1)))); 
end

end