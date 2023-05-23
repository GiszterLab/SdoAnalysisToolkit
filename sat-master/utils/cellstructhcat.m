%% Cell-Structure Horizonal Concatenation
% perform horizontal concatenation of array elements across a cell (dim 2)
% assumes that the 1st dimension is constant across all rows; tranpose if
% this assumption is violated

% 4.27.22 Update: Permits concentation of cell arrays of cells; requires the
% cellstructures to be conformable, but permits terminal contents of the cells
% to vary

% 4.28.22 Forking from base script; permits cellwise concatenation of
% structure elements contained within a cell arr; e.g.
% (cell{struct.field(row)}, used to combine like-elements from within the
% compiledDataCellArr as broken down by different elements (e.g. 'waves')

% NOTE: Script still in alpha development. May become unstable is used in
% improper context. 


% --> Things may still break down if there is a different number of
% elements per array per field...

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

function [arr,offset] = cellstructhcat(cl, SFIELD, SUBCELL_ROW_NO, LEVEL)

if ~exist('SUBCELL_ROW_NO', 'var'); SUBCELL_ROW_NO = 1; end

if ~exist('LEVEL', 'var'); LEVEL = 0; end

if ~iscell(SFIELD)
    fieldArr = {SFIELD}; %permit multiple fields to pass; 
else
    fieldArr = SFIELD; 
end
    
[cl_0, cl_max] = size(cl); %elements to iterate over; 

if (cl_0) == 1 && (cl_max == 1)
    %// passive pass-back; 
    arr = cl{1}; 
    offset = {}; 
    return
end
    
    
%_________ SCAN FOR CLASS/SIZE _________
formatLs = {}; 
formatSz = {}; 
formatFn = {}; %fieldnames
lv = cl; 
while true 
    % -- keep drilling down until we find the arr; 
    lv0 = lv; %lkup for n-1 level
    if isstruct(lv)
        formatLs{end+1} = 'struct'; 
        [szA, szB] = size(lv); 
        formatSz{end+1} = [szA, szB]; 
        if any(isfield(lv, fieldArr))
            fIdx = find(isfield(lv, fieldArr)); 
            lv = lv.(fieldArr{fIdx}); 
            formatFn{end+1} = fieldArr{fIdx}; 
            
        else
            disp("Cannot detect field from struct"); 
            break
        end
    elseif iscell(lv)
        [szA, szB] = size(lv); 
        formatSz{end+1} = [szA, szB]; 
        formatLs{end+1}  = 'cell'; 
        %
        formatFn{end+1} = []; 
        lv = lv{1}; 
    elseif isnumeric(lv)
        %// we found arr; 
        [szA, szB] = size(lv); 
        formatSz{end+1} = [szA, szB]; 
        break
    end
end
%_____________ END ____________

%// work backwards to determine shapes; 
lv = length(formatLs); 

if all(strcmp(formatLs, 'cell'))
    %// this is not actually a struct; use the cellhcat instead
    [arr,offset] = cellhcat(cl, LEVEL); 
    if nargout == 1 
        offset = []; 
    end 
    return
end

switch formatLs{lv}
    case 'struct'
        %// lowest non-numeric element is a struct.field relationship; 
        %// concat like elements within struct; 
        
        %// TODO; Layer this so that it is more robust
        
        colEl = cell(formatSz{lv}(2), formatSz{1}(2)); %column elements
        for c=1:formatSz{1}(2)
            for r1 = 1:formatSz{lv}(2) %number struct elements
                colEl{r1,c} = cl{1,c}(r1).(formatFn{lv}); 
            end
        end
        [arr, offset] = cellhcat(colEl, LEVEL); 
        if nargout == 1 
            offset = []; 
        end 
        return

        % .... 'cell' case... 
        
end

%% Mostly un-utilized code to wrap; 

ew = zeros(1,cl_max); %sz1
el = zeros(1,cl_max); %sz2

for cl_itt=1:cl_max 
    [ew(cl_itt), el(cl_itt)] = size(cl{cl_itt}.(SFIELD)); 
end 

% -- compensate for empty cells
el = el(el> 0); 
ew = ew(ew> 0); 

if ~all(ew == ew(1))
    %// mismatch in expectation; 
    ti = find(~(ew== mode(ew))); 
    for t = ti
        cl{t}.(SFIELD) = cl{t}.(SFIELD)'; 
    end
    % -- reset
    for cl_itt=1:cl_max 
        [ew(cl_itt), el(cl_itt)] = size(cl{cl_itt}.(SFIELD){SUBCELL_ROW_NO}); 
    end
end

%{
if ~all(ew==mode(ew))
    %//mismatch in expectation; 
    % --> Back-patch from cellstructvcat
    ti = find(~(ew== mode(ew))); 
    for t = ti
         cl{t}.(field) = cl{t}.(field)'; 
    end
    % -- reset
    for cl_itt=1:cl_max 
        [ew(cl_itt), el(cl_itt)] = size(cl{cl_itt}.(field){subcell_idx}); 
    end
end
%}    

if ~all(ew==mode(ew))
    disp("Input Cell Array is not conformable to horzcat"); 
    return
end


% -- handle arr vs. cell
 handl=class(cl{1}.(SFIELD));
switch handl
    % -- Original Use Case
    case 'double'
        arr = zeros(median(ew),sum(el)); 
        if LEVEL == 1
            LEVEL_XT = 1; 
            offset = zeros(size(arr)); 
        else
            LEVEL_XT = 0; 
        end
        
    case 'cell'
        arr = cell(median(ew),sum(el));
        LEVEL_XT = 0; 
end

el_itt = 1; 
for cll = 1:length(cl)
    %-- skip empty cells
    if isempty(cl{cll})
        continue
    end
    sz = size(cl{cll}.(SFIELD));  
    dim = find(sz == mode(ew)); %dimension against which to horzcat
    
    if dim == 1 
        %// default alignment; nRows as expected; 
        num_el = sz(2);
        arr(:,el_itt:el_itt+num_el-1) = cl{cll}.(SFIELD); 
    else
        num_el = sz(1); 
        arr(:,el_itt:el_itt+num_el-1) = cl{cll}.(SFIELD)';
        %// 1xN array instead of NxM arr; 
    end
    %
    if LEVEL_XT
        % -- Adjust BaseLine
        offset(:,el_itt:el_itt+numel-1) = arr(:,el_itt+num_el-1); 
    end
    
    el_itt = el_itt+num_el; 
end


if LEVEL_XT
    arr_out = arr+offset; 
    arr = arr_out; 
end

if nargout == 1
    offset = []; 
end

1; 
end