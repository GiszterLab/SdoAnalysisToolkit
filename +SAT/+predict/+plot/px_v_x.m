%% predictSDO_plot_px_v_x
% A method to visually compare predictions by looking at how the
% distributions of the predicted post-spike state line up with the assigned
% post-spike state. 
% Can reveal state-wise prediction behavior 
%
% INPUTS: 
%   'pdPx1' - Predicted Probability Distribution (Organized as a Mx1 column
%       vectors, over N events)
%   'x1'    - Observed post-spike state, organized as a [1xN] vector
%   OPTIONAL NAME-VALUE PAIRS: 
%       - 'subIndex'    - A subset of column indices to use for plotter. 
%       - saveFig       - [0/1]; whether to trigger the save module
%       - saveFormat    - ['png'/'svg'] 
%       - outputDirectory- String containing path. If not provided, will
%           query user

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function predictSDO_plot_px_v_x(pdPx1, x1, varargin)
%
p = inputParser; 
addParameter(p, 'subIndex', []); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

subIDX = pR.subIndex; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

if isempty(subIDX)
    subIDX = 1:length(x1); 
end
N_SPIKES = length(subIDX); 

[x1_x, x1_idx] = sort(x1(subIDX)); 

x1_IDX = (subIDX(x1_idx)); %back-lookup original columns from x1-ordered

% ==> subIDX = subset of pdPX1/x1 to plot for scatter (RNG spikes)

sfields = fields(pdPx1); 
N_FIELDS = length(sfields); 

nCols = ceil(sqrt(N_FIELDS)); 
nRows = ceil(N_FIELDS/nCols); 

maxVal = 0; 
for hh = 1:N_FIELDS
    maxVal = max(maxVal, max(max(pdPx1.(sfields{hh})))); 
end

figure; 
for hh = 1:N_FIELDS
    subplot(nRows, nCols, hh);
    imagesc(pdPx1.(sfields{hh})(:,x1_IDX)); 
    hold on; 
    scatter(1:N_SPIKES, x1_x, 'r', 'x'); 
    axis xy; 
    %
    title("PMF p[x,(s,s+\Deltat)] v. x(s)");
    xlabel(strcat("X(s,s+\Deltat)-Sorted subset of ", num2str(N_SPIKES), " events")); 
    ylabel("P[x,(s,s+\Deltat)]"); 
    %colormap('bone'); 
    colormap(flipud(bone)); %Inverted to white background
    caxis([0, maxVal]); 
    colorbar
    %text(5, 2, strcat(sfields{hh}), 'Color', [1,1,1],  'FontSize', 18); 
    text(5, 2, strcat(sfields{hh}), 'Color', [0,0,0],  'FontSize', 18); %black text
    text(N_SPIKES-10, 2, {'Observed', 'post-spike state'}, 'Color', 'r', 'FontSize', 8, 'HorizontalAlignment', 'right'); 
    1; 
end

if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'Predicted-P(x)_vs_Observed(X)', [0,0,1920,1080]); 
end

end