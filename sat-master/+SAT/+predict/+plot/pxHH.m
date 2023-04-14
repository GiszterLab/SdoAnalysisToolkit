%% predictSDO_plot_transitionMatrices (HH)
%
% Plotter for directly visualizing the various prediction structures, such
% as the transition matrices giving rise to the model hypotheses. Can also
% be used on predicted-state distributions directly. 
%
%
% INPUT
%   matStruct
%       A 1xN structure, which each field containing doubles data. 
%       - This may be predicted distributions of state, transition
%       matrices, or other probability-based data
% OPTIONAL NAME-VALUE PAIRS   
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Trevor S. Smith, 2023
% Drexel University College of Medicine

function pxHH(matStruct, varargin)
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 

%________
sfields  = fields(matStruct); 

N_FIELDS = length(sfields); 

N_COLS   = round(N_FIELDS/2); 

[N_BINS, N_ROWS] = size(matStruct.(sfields{1})); 

%
figure; 

for f = 1:N_FIELDS
    subplot(2,N_COLS,f); 
    mat = matStruct.(sfields{f}); 
    matType = SAT.sdoUtils.sdotype(mat); 
    if strcmp(matType, 'L')
        mat = mat + eye(N_BINS); 
    end
    imagesc(mat); 
    colorbar
    %
    if N_BINS == N_ROWS
        %// opt-out if not SDOs in
        line( [0, N_BINS], [0, N_BINS], 'color', [1, 1, 1], 'lineStyle', '--', 'lineWidth', 1.5); 
        axis square
    end
    axis xy
    title(strcat("Prediction H", num2str(f), " ", sfields{f})); 
    xlabel('x_0 State'); 
    ylabel('x_1 State'); 
end


if SAVE_FIG
    f = gcf; 
    if N_BINS == N_ROWS
        nameStr = "HH-TransitionMatrices"; 
    else
        nameStr = "hypothesized-Px"; 
    end
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, nameStr); 
end

end