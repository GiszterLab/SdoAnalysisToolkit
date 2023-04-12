%% plot_saveModule
% Internal shared macro to handle saving figures; ensure that exported svg
% files remain fully-editable for post-hoc modifications
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

% Trevor S. Smith, 2022
% Drexel University College of Medicine

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

if isempty(fDIM)
    fDIM = [0, 0, 1920, 1200]; 
end

if isempty(SAVE_DIR)
    SAVE_DIR = uigetdir([],"Select a Folder to save images to");
end

name = fullfile(SAVE_DIR, strcat(fName, ".", SAVE_FMT)); 
try
    set(f, 'Position', fDIM); 
catch
    %// appears when we pass as struct of figure handles (subplots) instead
    %of figure handles; Not ideal, as it will miss any other figures
    %generated in the script calling this function
    f = gcf; 
    set(f, 'Position', fDIM); 
end
    
switch SAVE_FMT
    %// 'painters' format used to maximize editable capabilities in
    %inkscape
    case 'png'
        print(f, name, '-dpng'); 
    case 'svg'
        print(f, '-painters', name, '-dsvg'); 
end

end




