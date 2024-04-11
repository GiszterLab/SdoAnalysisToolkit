%% CellHCat ("Cellwise Horizonal Concatenation")
% Macro to perform universal horizontal concatenation of array elements across a cell (dim 2)
% assumes that the 1st dimension is constant across all rows; tranpose if
% this assumption is violated.
%
%
% Potential Inputs and Behaviors: 
% --------------- 
% 1xN cell array: 
%     - Each element of the cell contains a 1xM doubles vector
%         ==> Output will be a 1xN*M doubles array
%     - Each element of the cell contains a Mx1 doubles vector
%         ==> Output will be a MxN doubles vector 
%     - Each element of the cell contains a KxM doubles array
%         ==> Output will be a KxM*N doubles Array, stacked
%            (Values of M must be equal within a column)
% Nx1 cell array: 
%     ==> Will transpose into a 1xN Array before processing
%
% KxN Cell Array:
%     - Each element of the cell contains a 1xM doubles vector
%         ==> Output will be a Kx1 cell containing a (NxM doubles Array)
%             (Values of N must be equal within a column)
%     - Each element of the cell contains a LxM doubles array
%         ==> Output will be a Kx1 cell containing a (K x M*N doubles Array)
%             (Values of M must be equal within a column)    
%
% Currently, the 'LEVEL' feature is only used when concatenating [Nx?]
% Double arrays. This option ensures the endpoints of each part of the
% cat'd array are aligned
% (although note that end point artifacts may mess with the mean of the
% signal). Level may be used to calculate either a constant offset for each
% concatenated section, or may be more smoothly varying to smooth the
% differential of a signal (as in a time series). 
% LEVEL = 0; No Offset (Maintain Signal Fidelity)
% LEVEL = 1; Constant Offset (Maintain relationships w/in section)
% LEVEL = 2; Nonlinear Offset (Optimize Differential)
% LEVEL = 3; Nonlinear Offset + Filter ( Maintain stationarity); 

% Copyright (C) 2023
% [Redacted for Double-Blind Review]
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

function [arr, offset] = cellhcat(cl, LEVEL)
%
if ~exist('LEVEL', 'var'); LEVEL = 0; end
if isa(cl, 'double'); arr = cl; offset = 0; return; end

%% Remove Completely Empty Columns
nonemptyIDX = ~cellfun(@isempty, cl); 
nonEmptyCols = any(nonemptyIDX,1); 

cl = cl(:,nonEmptyCols); 

% -- Num Rows [Expected Consistent]

[sz0y, sz0x] = size(cl); 

if any(sz0x == [0]) && any(~nonEmptyCols)
%if any(sz0x == [1,0]) && any(~nonEmptyCols)
    arr = cl; 
    return
end

% // Z_DIM Patch
% --> Assume missing dims are in the dimension of horzcat (2); 
nElemDim = cellfun(@ndims, cl); 
%maxDim = max(max(nElemDim)); 
if any(any(nElemDim > 2)) && any(any(nElemDim == 2))
    zLen = cellfun(@length, cl); 
    for yy = 1:sz0y
        for xx = 1:sz0x
            if nElemDim(yy,xx) <= 2
                cl{yy,xx} = reshape(cl{yy,xx}, [], 1, zLen(1)); 
                1; 
            end
        end
    end
end


%% Determine Cell Structure
try
    handl=class(cl{1});
catch
    handl = class(cl);
end

if sz0x == 1 && (sz0y>1)
    %// transpose column cell vects to horzcat
    cl = cl';
    [sz0y, sz0x] = size(cl);
end
if (sz0x == 1) || (sz0y == 1 )
    %// output as a doubles array
    celltype = ['Nx1_' handl]; 
    %// patch to skip complete-empty
    %__
    cl_IX = ~cellfun(@isempty, cl); 
    cl = cl(cl_IX); 
    % update;
    [sz0y, sz0x] = size(cl); 
    
else
    %// output as a cell array
    celltype = ['NxK_' handl]; 
end

%-- Num Rows [Expected consistent] 
el = cellfun(@size, cl, repelem( {1}, sz0y, sz0x) ); %'expected length'
%-- Num Cols [Expected Variable]
ew = cellfun(@size, cl, repelem( {2}, sz0y, sz0x) ); %'expected width'

el = reshape(el, sz0y, sz0x); 
ew = reshape(ew, sz0y, sz0x); 

switch celltype
    case {'Nx1_double', 'Nx1_cell', 'Nx1_logical', 'Nx1_char'}
        el2 = max(mode(mode(el)),1); %double-dimension median; expected consistent       
        if ~all(el(el>0) == el(find(el>0,1)))
            %// mismatch in expectation; 
            ti = find(~(el== el2) & ~el==0); 
            for t = ti
                %// Transpose cell element; (single indexing)
                cl{t} = cl{t}'; 
            end
            % -- reset
            el = cellfun(@size, cl, repelem( {1}, sz0y, sz0x) ); 
            ew = cellfun(@size, cl, repelem( {2}, sz0y, sz0x) ); 
            %
            el = reshape(el, sz0y, sz0x); 
            ew = reshape(ew, sz0y, sz0x); 
        end
    case {'NxK_double', 'NxK_logical', 'NxK_cell'}
        %// back-patch from cellvcat
        LI = (el>0) & ~isnan(el); 
        el2 = zeros(sz0y,1); 
        for yy=1:sz0y
            el2(yy) = max(mode(el(yy, LI(yy,:)))); 
        end
        el2(isnan(el2)) = 0; 
        %el2 = max(mode(el),1); 
        %
        if ~all(all(el == el2,1))
            ti = find(~(el== el2) & ~el==0);
            nTi = length(ti); 
            for t_0 = 1:nTi 
                t = ti(t_0); 
                %// Transpose cell element; (single indexing)
                cl{t} = cl{t}'; 
            end
            % -- reset
            el = cellfun(@size, cl, repelem( {1}, sz0y, sz0x) ); 
            ew = cellfun(@size, cl, repelem( {2}, sz0y, sz0x) ); 
            %
            el = reshape(el, sz0y, sz0x); 
            ew = reshape(ew, sz0y, sz0x); 
        end
end

% __ Checkpoint__
chkpt = all(round(sum(el,1)./sum(el>0,1)) == el2); 
if ~chkpt == 1
    val = round(sum(el,1)./sum(el>0,1)); 
    if ~all(val(~isnan(val)) == el2(~isnan(val)))
        %disp("Warning: Input Cell Array is not conformable to horzcat"); 
       % return
    end
end

%% Concatenate Data based on Type

switch celltype
    %-- Original Use Case
    case {'Nx1_double' 'NxK_double', 'NxK_logical', 'Nx1_char'}
        arr = cell(sz0y,1); 
        % -- can use rowwise normal horzcat
        for row=1:sz0y
            % __ back-patch from cellvcat
            if any(el(row,:) < 1)
                LI = el(row,:) > 0; 
            else
                LI = true(1, sz0x); 
            end
            arr{row} = horzcat(cl{row,LI});
        end
        offset = cell(sz0y,1);        
        %_______
        switch LEVEL
            case 0
                %% No Offsets
                for row = 1:sz0y
                    offset{row} = zeros(size(arr{row})); 
                end
            case 1
                %% Constant offsets
                for row = 1:sz0y
                    offset{row} = zeros(size(arr{row})); 
                    for xx = 2:sz0x
                        L_Pos = sum( ew(row,1:xx-1)+1); 
                        offset{row}(L_Pos:end) = offset{row}(L_Pos:end)+cl{row,xx-1}(end); 
                    end
                end
                % __ Apply Leveling
                for row = 1:sz0y
                    arr{row} = arr{row} - offset{row}; 
                end
            case {2,3}
                %% nonlinear offsets
                for row = 1:sz0y
                    %// smooth the differentials to fix the endpoints; 
                    x0 = arr{row}(:,1); 
                    dxt = diff([zeros(size(x0)), arr{row}],[],2); 
                    %// assume endpoint leveling artifacts only affect adj. xt
                    ff_dxt = movmedian(dxt', 3)'; %double transpose for NxK
                    x1 = cumsum(ff_dxt')'; 
                    if LEVEL == 3
                       %// filter-level background;  
                       fLen = min(ew(row, (ew(row,:) > 1)));
                       x_bck = movmedian(x1', fLen)'; 
                       xt = x1 - x_bck + x0; 
                    else
                        xt = x1 + x0; 
                    end
                    offset{row} = arr{row}-xt; 
                    arr{row} = xt; 
                end        
        end
        %____ Process Output
        if strcmp(celltype, 'Nx1_double')
            %//  unwrap cells; 
            arr     = arr{1}; 
            offset  = offset{1}; 
        end
        % __ COMPLETE 
        if nargout == 1
            offset = []; 
        end
        return
        
    case 'Nx1_cell'
        arr = cell(el2*sz0y, sum(ew(:,1))); 
    case 'NxK_cell'
        % -- flattening cells of cells
        arr = cell(sz0y, sum(ew(:,1))); 
end
      

%% ++__ CELLWISE APPENDING ___ ++

el_itt = 1; 
for cll = 1:sz0x
    if isempty(cl{1,cll})
        continue
    end    
    %// positions w/in final cell array; 
    row_itt0 = 1;
    row_itt1 = el(1,cll); 
    num_el = ew(1, cll); 
    for row = 1:sz0y
        %// each row of final array; 
        %__
        
        switch celltype
            case 'Nx1_cell'
                arr(row_itt0:row_itt1,el_itt:el_itt+num_el-1) =  cl{row, cll};      
                
            case 'NxK_cell'
                %// Requires non-homogeneous transforms/checks
                %// I have not found a case which requires this yet
                
                %[elem_y, elem_x] = cellfun(@size, cl{row, cll}); 
                %cellElem = cell(median(ew), sum(el)); 
        
                disp("NxK cell type not implemented yet")
        end
        row_itt0 = row_itt1+1; 
        row_itt1 = el(row, cll)+row_itt1; 
    end
    el_itt = el_itt+num_el; 
end

%// offset doesn't make sense when re-arranging cells
%// Just pass empties to fit sizes for later

if nargout == 2
    [elem_szy, elem_szx] = size(arr); 
    offset = cell(elem_szy, elem_szx);
    for yy = 1:elem_szy
        for xx = 1:elem_szx
            offset{yy,xx} = cell(size(arr{yy,xx})); 
        end
    end
else
    offset = []; 
end

end