%% plotSDO_quiverSDO
%
% Plots the Quiver SDO, a representation of the coarse transition SDO in a
% 1D fashion. The Diagonal component of the SDO is now treated as a linear
% component, with directional components coming off for transitions
% above/below diagonal (transition to higher/lower states)
%
% The Quiver plot assumes that the matrix transitions and SDO effects are
% concentrated around the diagonal, and hence aggregates effects of domains.
% 
% PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%       sdoMatrix: 
%           - The target spike-triggered SDO to plot
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'filter',        : [0/1]. If 1, use a diagonal gaussian smoothing filter. 
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position
%       'normMat'        : An optional matrix to pass, matching the size of
%           the 'sdoMat', which is used for elementwise normalization. 
%       'headPos'        : ['end'/'center']: Position for the arrowheads of
%           the quiver plots. Defaults to 'end'

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function plotSDO_quiverSDO(sdoMatrix, varargin)
defaultHeadPos      = 'end'; %// ['end'/'center']
expectedHeadpos     = {'end', 'center'}; 
%validNumber = @(x) isnumeric(x); 
p = inputParser; 
addParameter(p, 'filter', 1); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
% -- 
addParameter(p, 'normMat', ones(size(sdoMatrix))); 
addParameter(p, 'headPos', defaultHeadPos, ...
    @(x) any(validatestring(x,expectedHeadpos)) ); 
parse(p,varargin{:}); 
pR = p.Results; 

FILTER      = pR.filter; 
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
targetNorm  = pR.normMat; 
headPos     = pR.headPos; 

if FILTER
    sdoMatrix = SAT.sdoUtils.ffdiag([], 1, sdoMatrix,1); 
end

plotMat = sdoMatrix./targetNorm;

N_STATES = length(plotMat); 

t_diag = diag(plotMat); %'target diagonal'

% triu = upper triangle of matrix; main diagonal+1 ; sum
lc_diag = sum(triu(plotMat,1)); 
lc_diag2 = sum(abs(triu(plotMat,1))); %mag

%// due to orientation, upper diag == transition to lower states

% tril = lower triangle of matrix, main diagonal-1; sum
up_diag = sum(tril(plotMat,-1));
up_diag2 = sum(abs(tril(plotMat,-1))); %mag
%// due to orientation, lower diag == transition to higher states

%% Find Upper Vectors
uv_v = abs(up_diag); 
in_uv       = []; %inverse orientation vectors; 
in_uv_y0    = []; %y-origin point; 
in_uv_v     = [];   %ylength(inverse)

for xx =1:N_STATES
    %if t_diag(xx) > up_diag(xx)
    if max(t_diag(xx),0) > up_diag(xx)
        in_uv = [in_uv xx]; 
        %// Inward facing vector; origin is == mag(x)
        in_uv_y0 = [in_uv_y0 uv_v(xx)];
        in_uv_v  = [in_uv_v -uv_v(xx)]; %// new y-dist 
    end
end

%% Find Lower Vectors

lv_x = 1:N_STATES;
lv_v = -1*abs(lc_diag); 

in_lv = []; %inverse orientation vectors; 
in_lv_y0 = []; %y-origin point; 
in_lv_v =[];   %ylength(inverse)

for xx =1:N_STATES
    %if t_diag(xx) > lc_diag(xx)
    if max(t_diag(xx),0) > lc_diag(xx)
        %// Inward facing vector; origin is == mag(x)
        in_lv = [in_lv xx]; 
        %// Inward facing vector; origin is == mag(x)
        in_lv_y0 = [in_lv_y0 lv_v(xx)];
        in_lv_v  = [in_lv_v -lv_v(xx)]; %// new y-dist 
        
    end
end


%% Concatenate and plot; 
figure; 
hold on
%// Plot a horizontal 
plot(1:N_STATES, zeros(1,N_STATES), 'lineWidth', 2, 'color', 'k', 'LineStyle', '--'); 

%// Plot Diagonal for Baseline
p1 = plot(1:N_STATES, t_diag, 'lineWidth', 2, 'color', [0.8500 0.3250 0.0980]); 

%// Find dpx regions which are non-zero and point away from diagonal
u_rx = setdiff(lv_x(uv_v~=0),(in_uv)); 
u_ry = uv_v(u_rx);

l_rx = setdiff(lv_x(lv_v~=0),(in_lv)); 
l_ry = lv_v(l_rx);  

%// Swap to unit-wise draw line
for xx = 1:N_STATES
    p2 = line([(xx), (xx)], [abs(up_diag((xx))) 0], 'lineWidth', 2, 'color', 'b'); 
    %line([u_rx(xx), u_rx(xx)], [u_ry(xx), 0], 'lineWidth', 2, 'color', 'b'); 
    p3 = line([(xx), (xx)], [up_diag2((xx)) 0], 'lineWidth', 1, 'color', 'b', 'LineStyle', '--'); 
end
for xx = 1:N_STATES
    p4 = line([(xx), (xx)], [-abs(lc_diag((xx))) 0], 'lineWidth', 2, 'color', 'g'); 
    %line([u_rx(xx), u_rx(xx)], [u_ry(xx), 0], 'lineWidth', 2, 'color', 'b'); 
    p5 = line([(xx), (xx)], [-lc_diag2((xx)) 0], 'lineWidth', 1, 'color', 'g', 'LineStyle', '--'); 
end

u_iv_y = zeros(size(in_uv)); 
l_iv_y = zeros(size(in_lv)); 

if strcmp(headPos, 'center')
    %// Only half the ones if deviation required
    u_ry = u_ry/2; 
    l_ry = l_ry/2; 
    u_iv_y = abs(up_diag(in_uv)/2); 
    l_iv_y = -abs(lc_diag(in_lv)/2); 
end

% -- Away-from-diagonal
scatter(u_rx, u_ry, 100, 'b', 'filled', 'Marker', '^'); 
scatter(l_rx, l_ry, 100, 'g', 'filled', 'Marker', 'v'); 
% -- Towards Diagonal
scatter(in_uv, u_iv_y, 100, 'b', 'filled', 'Marker', 'v');
scatter(in_lv, l_iv_y, 100, 'g', 'filled', 'Marker', '^'); 

%legend({'Shift towards higher states', 'Shift towards lower states'});

hold off
if FILTER
    filtName = ' (filtered)';
else
    filtName = ' (raw)'; 
end
if ~isempty(targetNorm)
    targName = ' (Normalized)'; 
else
    targName = ''; 
end

title(strcat('Gross Directional SDO Effect', targName, ' Statewise', filtName)); 

%{
if ~isempty(targetNorm)
    title("Gross Directional SDO Effect (Normalized), Statewise");
else
    title("Gross Directional SDO Effect, Statewise");
end
%}
ylabel('Magnitude of \DeltaP(State)'); 
%// both above/below diagonal should be (+) because we're using magnitude
%of dp(x), not direction; 
yticklabels(abs(yticks))

xlabel('State');
legend([p1, p2, p3, p4, p5], {'Diagonal Elements', 'Above Diagonal Elements (sum)', 'Above Diagonal Elements (Magnitude)', 'Below-Diagonal Elements (sum)', 'Below-Diagonal (Magnitude)'}); 

%legend({'Diagonal Elements', 'Above-Diagonal Elements', 'Below-Diagonal Elements'}); 
%// Need to update with min/max amplitude

ymax = max(uv_v);
ymin = min(lv_v);
text(1, ymax*0.9, 'Transition to Upper States'); 
text(1, ymin*0.9, 'Transition to Lower States');
hold off

axis([1,N_STATES, -inf, inf]); 

%% -- Save Module
if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'SDO_QuiverPlot'); 
end

end
