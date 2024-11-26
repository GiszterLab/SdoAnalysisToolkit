%% plot_saveModule
% Internal shared macro to handle saving figures; ensure that exported svg
% files remain fully-editable for offline post-hoc modifications
%
% Function should be fully defined
% Generally, this function will only be called from internal code, 
% not from the user
%
% PARAMETERS
% f = figure to save (passed as figure handle); 
% SAVE_DIR = target save directory; requested from user, if left empty
% SAVE_FMT = {'png', 'svg'}; 
% fName    = target filename to save, up to extension
% fDIM      = (Optional) size of image to save, specifed as a [X1,X2,Y1,Y2]
%   vect; if empty or excluded [0,0,1920,1200]; 

% 2.26.2024 - Added capability for no-resize, by setting fDim = 0; 

% 9.23.2024 - Added 'fig' as an alternative format, for saving Matlab figs

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

function plot_saveModule(f, SAVE_DIR, SAVE_FMT, fName, fDIM)
if ~exist('fDIM', 'var')
    fDIM = [0, 0, 1920, 1200]; 
end
if ~exist('SAVE_DIR', 'var')
    SAVE_DIR = []; 
end
if ~exist('SAVE_FMT', 'var')
    SAVE_FMT = 'svg';
end
if ~exist('fName', 'var')
    fName = []; 
end
if ~exist('f', 'var')
    f = gcf; 
end

if isempty(fDIM)
    fDIM = [0, 0, 1920, 1200]; 
end

if all(fDIM == 0)
    RESIZE = 0; 
else
    RESIZE = 1; 
end

if isempty(SAVE_DIR)
    SAVE_DIR = uigetdir([],"Select a Folder to save images to");
end

name = fullfile(SAVE_DIR, strcat(fName, ".", SAVE_FMT)); 
if RESIZE
    try
        set(f, 'Position', fDIM); 
    catch
        %// appears when we pass as struct of figure handles (subplots) instead
        %of figure handles; Not ideal, as it will miss any other figures
        %generated in the script calling this function
        f = gcf; 
        set(f, 'Position', fDIM); 
    end
end
    
switch SAVE_FMT
    %// 'painters' format used to maximize editable capabilities in
    %inkscape
    case 'png'
        print(f, name, '-dpng'); 
    case 'svg'
        print(f, '-painters', name, '-dsvg');
    case 'fig'
        %09.23.2024
        savefig(f, name); % default save; 

end

end




