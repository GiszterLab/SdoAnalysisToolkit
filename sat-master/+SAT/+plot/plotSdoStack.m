%% plotSdoStack
% Generic method for plotting 3D SDOs into a 2D Matrix; Matrix diagonals
% are aligned on the Y = X, for easier interpretation. 
%
% INPUTS
%   - L_STACK   = [N_STATES, N_STATES,N_OBS] matrix of SDOs, indexed by DIM3.
%   - names     = {1,N_OBS} list of names (cell)
% OUTPUTS
%   - f         = figure handle

%_______________________________________
% Copyright (C) 2025 Trevor S. Smith
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

function [f] = plotSdoStack(L_Stack, names)

if ~exist('names', 'var')
    names = []; 
end

[N_STATES, ~, N_L] = size(L_Stack); 

%%

% __ We'll plot these all sequentially in a grid; 

N_COLS = ceil(sqrt(N_L)); 
N_ROWS = ceil(N_L/N_COLS); 

% __ Concentate and tile into a single 2d array
flatArr = -inf*ones(N_ROWS*N_STATES, N_COLS*N_STATES); 
zz = 1; 
for rr = 1:N_ROWS
    r0 = (rr-1)*N_STATES+1; 
    r1 = rr*N_STATES; 
    for cc = 1:N_COLS
        c0 = (cc-1)*N_STATES+1; 
        c1 = cc*N_STATES; 
        %
        if zz <= N_L
            flatArr(r0:r1,c0:c1) = flipud(L_Stack(:,:,zz));
        end
        zz = zz+1; 
    end
end

if nargout == 1
    f = figure;
end
imagesc(flatArr); 

% Use custom heatmap; 
arrMax = max(flatArr, [], 'all'); 
arrMin = min(flatArr(~isinf(flatArr)), [], 'all'); % avoid -inf; 

cMap = SAT.sdoUtils.getSdoColormap([arrMax, arrMin]); 

ax = gca; 

colormap(ax, cMap); 

% Cross dividing lines; 
for cc = 1:N_COLS-1
    xline(cc*N_STATES+0.5, 'LineStyle', ':', 'color', 'k'); 
end
for rr = 1:N_ROWS-1
    yline(rr*N_STATES+0.5, 'LineStyle', ':', 'color', 'k'); 
end

%  __ apply diagonal lines; 

% all intial values; 
%x0 = [ zeros(1, N_ROWS) N_STATES:N_STATES:(N_ROWS-1)*N_STATES]; 


%% plot sdoStack
% Generic method for plotting 3D SDOs into a 2D Matrix; Matrix diagonals
% are aligned on the Y = X, for easier interpretation. 
%x0 = [(0:N_STATES:N_STATES*N_ROWS-N_STATES) (N_ROWS*N_STATES-N_STATES:-N_STATES:0)]; %(N_STATES:N_STATES: N_STATES*N_COLS-N_STATES)]; 
x0 = [zeros(1,N_ROWS), (N_STATES:N_STATES:(N_ROWS)*N_STATES)+0.5]; 
x1 = [(N_STATES:N_STATES:N_STATES*N_ROWS) N_STATES*(N_ROWS+1)*ones(1,N_ROWS)]; %(N_STATES*N_ROWS-N_STATES:-N_STATES:0)];
y0 = [(N_STATES:N_STATES:N_STATES*N_ROWS) N_STATES*N_ROWS*ones(1,N_ROWS)]; 
y1 = [zeros(1, N_COLS) N_STATES:N_STATES:N_STATES*(N_ROWS-1)]; 


%x0 = x0+0.5; 
x1 = x1+0.5; 
y0 = y0+0.5; 
y1 = y1+0.5; 

for d = 1:length(y1) %diagonals; 
    line([x0(d) x1(d)], [y0(d) y1(d)], 'LineStyle', '--', 'lineWidth', 0.5, 'color', 'k'); 
end

% --- add for nulls --- 
if N_L < (N_ROWS*N_COLS)
    % These will, by def, be in the last row.
    yy = (N_ROWS*N_STATES-0.5*N_STATES); % approximately midpoint.
    xx = setdiff(1:N_COLS, mod(N_L,N_COLS))*N_STATES - (N_STATES/2);
    for x = 1:length(xx)
        % Default null = nan == blue
        text(xx(x), yy, "N/A", 'Color', 'White')         
    end
end
% --- add name, if we have --- 
if ~isempty(names)
    xv = repmat( (0:N_COLS-1)*N_STATES+N_STATES/2,  1, 3); 
    y0 = repmat(((0:N_ROWS-1)*N_STATES+N_STATES/10), 3, 1);
    yv = y0();
    for ll = 1:N_L
        text(xv(ll), yv(ll), names{ll}, 'Color', 'Black'); 
    end
end
% 

x_v = zeros(1,2*N_ROWS); 
x_t = zeros(1,2*N_ROWS); 
for rr = 1:N_ROWS
    i0 = (rr-1)*2+1; 
    i1 = rr*2; 
    x_v(i0:i1) = [N_STATES*rr-1, N_STATES*rr]; 
    x_t(i0:i1) = [1, N_STATES]; 
end
for cc = 1:N_COLS
    i0 = (cc-1)*2+1; 
    i1 = cc*2; 
    y_v(i0:i1) = [N_STATES*cc-1, N_STATES*cc]; 
    y_t(i0:i1) = [1, N_STATES]; 
end

xticks(x_v); 
yticks(y_v); 
xticklabels(x_t); 
yticklabels(y_t); 

end