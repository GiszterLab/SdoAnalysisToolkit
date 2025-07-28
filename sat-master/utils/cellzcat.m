%% cell-z-concatenation (cellzcat)
% Take MxN cell array, with each cell element containing a k x j doubles
% array; 'z-stack' data into a {1 x N} cell containing (k x j x m) elements
% or {M x 1} cell containing (k x j x n) elements
%
% INPUTS
%   c - cell Array; 
%   DIR = [1/2] (Default = 1); 

% TODO: Increase checks, on par with cellvcat, cellhcat

% Trevor S Smith, 2023, 
% Drexel University College of Medicine

function zCell = cellzcat( c, DIR)
if ~exist('DIR', 'var')
    DIR = 1; 
end

TRANSPOSE = false;

if DIR == 2
    TRANSPOSE = true; 
    c = c'; 
end

%// default assume 'vertcat stack'
[sz_y, sz_x] = size(c); 


elemType = class(c{1,1}); 

switch elemType
    case 'double'
        zCell = cell(1, sz_x); 
        for xCol = 1:sz_x
            %// assumed homogenous elements (at least in the direction of cat)
            [el_sz_y, el_sz_x] = size(c{1,xCol}); 
             
            zArr = nan*ones(el_sz_y, el_sz_x, sz_y); 
            for yRow = 1:sz_y
                if ~isempty(c{yRow,xCol})
                    zArr(:,:,yRow) = c{yRow, xCol}; 
                end
            end
            zCell{xCol} = zArr; 
        end
    if xCol == 1
        zCell = zCell{1}; 
    end

    case 'cell'
        %// Here we assume that cell sizes are maintained; 
       [elem_y, elem_x] = size(c{1,1}); 
       zCell = cell(elem_y, elem_x, sz_x); 
       
       for y = 1:sz_y
           %zCell(:,:,y) = c(y); 
           zCell(:,:,y) = c{y}; 
       end     
end



if TRANSPOSE
    zCell = zCell';
end

end