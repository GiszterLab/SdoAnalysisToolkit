%% CellVCat ("Cellwise Vertical Concatenation")
% perform vertical concatenation of array elements down a cell (dim 1)
% assumes that the 2nd dimension is constant across all rows; tranpose if
% this assumption is violated

% Potential Inputs and Behaviors: 
% --------------- 
% Nx1 cell array: 
%     - Each element of the cell contains a 1xM doubles vector
%         ==> Output will be a NxM doubles array
%     - Each element of the cell contains a Mx1 doubles vector
%         ==> Output will be a N*Mx1 doubles vector 
%     - Each element of the cell contains a KxM doubles array
%         ==> Output will be a N*K x M doubles Array, stacked
%            (Values of M must be equal within a  column)
% 1xN cell array: 
%     ==> Will transpose into a Nx1 Array before processing
%
% KxN Cell Array:
%     - Each element of the cell contains a 1xM doubles vector
%         ==> Output will be a 1xN cell containing a (KxM doubles Array)
%             (Values of M must be equal within a column)
%     - Each element of the cell contains a LxM doubles array
%         ==> Output will be a 1xN cell containing a (K*L x M doubles Array)
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

function [arr, offset] = cellvcat(cl, LEVEL)

if ~exist('LEVEL', 'var'); LEVEL = 0; end
if isa(cl, 'double'); arr = cl; offset = 0; return; end

if isempty(cl)
    arr = cl; 
    return; 
end

%% Remove Completely Empty Rows
nonemptyIDX = ~cellfun(@isempty, cl); 
nonEmptyRows = any(nonemptyIDX,2); 

cl = cl(nonEmptyRows, :); %reset array

%% Get size

[sz0y, sz0x] = size(cl); 

if (sz0y == 0) || (sz0x == 0)
    %// if any empties, return blank
    arr = cl; 
    return
end

if sz0y == 1 && any(~nonEmptyRows)
    %// if we removed rows (i.e. passed in a cell), and only 1 element
    %remains, output reduced cell
    arr = cl;
    return
end


%% Determine Cell Structure; 
try 
    handl = class(cl{1});
catch
    handl = class(cl);
end

if sz0y == 1 && (sz0x>1)
    %transpose 1xN arrs --> Nx1 arrs
    cl = cl';
    [sz0y, sz0x] = size(cl); 
end

if (sz0y == 1) || (sz0x == 1)
    celltype = ['Nx1_' handl];
    %// output will be a doubles array
    %// patch to skip complete-empty
    %__    
    cl_IX = ~cellfun(@isempty, cl); 
    cl = cl(cl_IX); 
    % update; 
    [sz0y, sz0x] = size(cl); 
else
    celltype = ['NxK_' handl];
    %// output will be a cell array
end

% -- Num Rows [Expected variable]
el = cellfun(@size, cl, repelem( {1}, sz0y, sz0x) ); %'expected length'
%-- Num Cols [Expected consistent] 
ew = cellfun(@size, cl, repelem( {2}, sz0y, sz0x) ); %'expected width'

el = reshape(el, sz0y, sz0x); 
ew = reshape(ew, sz0y, sz0x); 

switch celltype
    case {'Nx1_double' 'Nx1_cell'}
        ew2 = max(mode(mode(ew)),1);
        %
         if ~all(ew(ew>0) == ew(find(ew>0,1)))
            %// mismatch in expectation; 
            ti = find(~(ew== ew2) & ~ew==0); 
            
            for i = 1:length(ti)
                t = ti(i); 
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

    case {'NxK_double', 'NxK_cell'}
        LI = (ew> 0) & ~isnan(ew);  
        ew2 = zeros(1,sz0x); 
        for xx=1:sz0x
            ew2(xx) = max(mode(ew(LI(:,xx), xx))); 
        end

        % __ patch 
        ew2(isnan(ew2)) = 0; 

        %ew2 = max(mode(ew),1); 
        %ew2 = mode(ew); %this is columnwise; expectation
        %
        if ~all(ew == ew2,1) %columnwise check for ew(col) = ew(:,col)
            ti = find(~(ew== ew2) & ~el==0); 
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

%// new patch from cellhcat; 
chkpt = all(round(sum(ew,1)./sum(ew>0,1)) == ew2); 
if ~chkpt == 1
    val = round(sum(ew,1)./sum(ew>0,1)); 
    if ~all(val(~isnan(val)) == ew2(~isnan(val)))
        %disp("WARNING: Input Cell Array is not conformable to vertcat"); 
        %return
    end
end

%% Concatenate Data Based on Type

switch celltype
    % -- Original Use Case
     case {'Nx1_double' 'NxK_double'}   
        arr = cell(1, sz0x); 
        % -- can use colwise normal vertcat
        for col=1:sz0x
            if any(ew(:,col) < 1)
                LI = ew(:,col) > 0; 
            else
                LI = true(sz0y,1); 
            end
            %// patch for missing cell elements
            arr{1, col} = vertcat(cl{LI,col}); 
        end
        offset = cell(1,sz0x); 
        switch LEVEL
            case 0
                %% No Offsets
                for col=1:sz0x
                    offset{col} = zeros(size(arr{col})); 
                end
            case 1
                %% Constant Offsets
                for col = 1:sz0x
                    offset{col} = zeros(size(arr{col})); 
                    for yy = 2:sz0y
                        L_Pos = sum(el(col,1:yy-1)+1); 
                        offset{col}(L_Pos:end) = offset{col}(L_Pos:end)+cl{yy-1,col}(end); 
                    end
                end
                %// Apply Leveling
                for col = 1:sz0x
                    arr{col} = arr{col} - offset{col}; 
                end
            case {2,3}
                %% Nonlinear Offsets
                for col = 1:sz0y
                    %// smooth the differential to fix the endpoints; 
                    x0 = arr{col}(1,:); 
                    dxt = diff([zeros(size(x0)), arr{col}]); 
                    %// assume endpoint leveling artifacts only affect adj.
                    %xt
                    ff_dxt = movmedian(dxt,5); 
                    x1 = cumsum(ff_dxt); 
                    if LEVEL == 3
                        %// filter-level background
                        fLen = min(el((el(:,col) > 1), col)); 
                        x_bck = movmedian(x1, fLen); 
                        xt = x1 - x_bck + x0; 
                    else
                        xt = x1+x0; 
                    end
                    offset{col} = arr{col}-xt; 
                    arr{col} = xt; 
                end
        end
        %__ Process Output; 
        if strcmp(celltype, 'Nx1_double')
            %// unwrap cells
            arr = arr{1}; 
            offset = offset{1}; 
        end
        % __ COMPLETE 
        if nargout == 1
            offset = []; 
        end
        return
        
    case 'Nx1_cell'
        arr = cell(sum(el(:,1)),ew2*sz0x);  
    case 'NxK_cell'
        % -- will be flattening cells of cells
        arr = cell(sum(el(:,1)), sz0x); 
end

%% ++__ CELLWISE APPENDING ___ ++
        
ew_itt = 1; 
for cll = 1:sz0y
%for cll = 1:size(cl,1) %for each 'row'
    %-- skip empty cells
    if isempty(cl{cll})
        continue
    end
    col_itt0 = 1;
    col_itt1 = ew(cll,1); 
    num_el = el(cll,1); 
    for col = 1:sz0x

        % -- Probably not best to have the switch here, but whatever
        switch celltype
            case {'Nx1_double', 'Nx1_cell'}
                %arr(ew_itt,(col-1)*sum(ew(1:col))+1:col*sum(ew(1:col))) = cl{cll, col}; 
                arr(ew_itt:ew_itt+num_el-1,col_itt0:col_itt1) =  cl{cll, col};

            case { 'NxK_cell'}
                disp("NxK cell type not implemented yet")
        end
        col_itt0 = col_itt1+1; 
        col_itt1 = ew(cll,col)+col_itt1; 
    end
    
    ew_itt = ew_itt+num_el; 
end 


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