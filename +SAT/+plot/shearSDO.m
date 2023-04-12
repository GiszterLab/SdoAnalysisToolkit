%% plotSDO_shearSDO
%
% plot diagonal Band of SDO which contain the majority of the SDO effects,
% sheared, such that the diagonal is on the horizonal axis. 
%
% PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%       sdoMatrix: 
%           - The target spike-triggered SDO to plot
%   OPTIONAL POSITIONAL ARGUMENTS
%       N_BANDS: 
%           - [integer]: Number of diagonals off main-diagonal to include.
%           If not provided, default to 1/8 max states; 
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Trevor S. Smith, 2022

function plotSDO_shearSDO(sdoMatrix, varargin)
p = inputParser; 
addOptional(p, 'N_BANDS', []); 
addParameter(p, 'filter', 1); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

FILTER      = pR.filter; 
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
N_BANDS     = pR.N_BANDS; 
%_______

N_BINS = size(sdoMatrix,1); 
if isempty(N_BANDS)
    N_BANDS = round(N_BINS/8); 
end

if FILTER
    sdoMatrix = SAT.sdoUtils.ffdiag([], 1, sdoMatrix,1); 
end

%// Columnwise shear, with diagonal now the horizonal
shearMat = zeros(N_BINS*2-1,N_BINS); 
%// Apply transform such that row = numStates = diag of original; 
for col=1:N_BINS 
    shearMat(N_BINS-col+1:2*N_BINS-col,col) = (sdoMatrix(:,col)); 
end

%% Plot Shear Matrix over queried region

figure;
hold on
imagesc(shearMat)
%// fill shear undefined regions w/ black
sp_lower = polyshape([0.5,0.5,N_BINS+0.5], [0.5,N_BINS+0.5,0.5]); 
sp_upper = polyshape([0.5, N_BINS+0.5, N_BINS+0.5], [2*N_BINS-0.5, 2*N_BINS-0.5, N_BINS-0.5]); 
plot(sp_lower, 'FaceColor', 'black', 'FaceAlpha', 1); 
plot(sp_upper, 'FaceColor', 'black', 'FaceAlpha', 1); 

%//Upperbound of shear
line(1:N_BINS, N_BINS:-1:1 , 'Color', 'white', 'LineStyle', '--')
%//Lowerbound of shear
line(1:N_BINS, N_BINS*2-1:-1:N_BINS, 'Color', 'white', 'LineStyle', '--')
%// 'Diagonal' of old matrix now horizonal here
line(1:N_BINS, N_BINS*ones(1, N_BINS), 'Color', 'red', 'lineWidth', 2); 

% -- > Now set axes according to the desired region to map; 
xlim([1,N_BINS]); 
try
    ylim([N_BINS-N_BANDS,N_BINS+N_BANDS]); 
catch
    ylim([1,2*N_BINS-1]); 
end

text(1,N_BINS+0.1*N_BINS, 'Main Diagonal', 'Color', 'red'); 


if FILTER
    title("Diagonal-Sheared SDO Matrix (Filtered)");
else
 title("Diagonal-Sheared SDO Matrix");    
end
xlabel("X_0 State"); 
ylabel("\Deltap(state), relative to diagonal");

yt = yticks; 
yticklabels(yt-N_BINS); 
colorbar;

hold off

    % -- Save Module
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "Shear_SDO", [0 0 1080 720]); 
end
    
end