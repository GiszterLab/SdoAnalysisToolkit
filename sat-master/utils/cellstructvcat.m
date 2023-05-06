%% CellHorzCat
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


function [arr] = cellstructvcat(cl, SFIELD, SUBCELL_ROW_NO, LEVEL)

if ~exist('subcell_idx', 'var'); SUBCELL_ROW_NO = 1; end

if ~exist('LEVEL', 'var'); LEVEL = 0; end

cl_max = size(cl,2); %elements to iterate over; 

if ~iscell(SFIELD)
    fieldArr = {SFIELD}; %permit multiple fields to pass; 
else
    fieldArr = SFIELD; 
end
    
%ew = zeros(1,cl_max); %sz1
%el = zeros(1,cl_max); %sz2

%_____ SCAN FOR CLASS/SIZE__________
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
    [arr,offset] = cellvcat(cl, LEVEL); 
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
        [arr, offset] = cellvcat(colEl, LEVEL); 
        if nargout == 1 
            offset = []; 
        end 
        return

        % .... 'cell' case... 
        
end

%% 
%{
for cl_itt=1:cl_max 
    try
        [ew(cl_itt), el(cl_itt)] = size(cl{cl_itt}.(field)); 
    catch
        xt = cl{cl_itt}.(field); 
        [ew(cl_itt), el(cl_itt)] = size(xt); 
    end
        
end 
%}

ew = zeros(1,cl_max); %sz1
el = zeros(1,cl_max); %sz2

for cl_itt=1:cl_max 
    [ew(cl_itt), el(cl_itt)] = size(cl{cl_itt}.(SFIELD)); 
end 


% -- compensate for empty cells
el = el(el> 0); 
ew = ew(ew> 0); 

if ~all(el == el(1))
    %// mismatch in expectation; 
    ti = find(~(el== mode(el))); 
    for t = ti
        cl{t}.(SFIELD) = cl{t}.(SFIELD)'; 
    end
    % -- reset
    for cl_itt=1:cl_max 
        [ew(cl_itt), el(cl_itt)] = size(cl{cl_itt}.(SFIELD){SUBCELL_ROW_NO}); 
    end
end

if ~all(el==mode(el))
    disp("Input Cell Array is not conformable to horzcat"); 
    return
end


% -- handle arr vs. cell
try
     handl=class(cl{1}.(SFIELD));
catch
    handl = class(cl{1}(1).(SFIELD)); 
end
switch handl
    % -- Original Use Case
    case 'double'
        arr = zeros(sum(ew),median(el)); 
    case 'cell'
        arr = cell(sum(ew),median(el));
end

ew_itt = 1; 
for cll = 1:length(cl)
    %-- skip empty cells
    if isempty(cl{cll})
        continue
    end
    tmp = cl{cll}.(SFIELD); %work-around 
    sz = size(tmp); 
    dim = find(sz == mode(el)); %dimension against which to vertcat
    
    if dim == 1 
        %// default alignment; nRows as expected; 
        num_el = sz(2);
        %arr(ew_itt:ew_itt+num_el-1,:) = cl{cll}.(field); 
        arr(ew_itt:ew_itt+num_el-1,:) = tmp; 
    else
        num_el = sz(1); 
        %arr(ew_itt:ew_itt+num_el-1,:) = cl{cll}.(field)';
        try
            arr(ew_itt:ew_itt+num_el-1,:) = tmp';
        catch
            arr(ew_itt:ew_itt+num_el-1,:) = tmp;
        end
        %// 1xN array instead of NxM arr; 
    end
    ew_itt = ew_itt+num_el; 
end

end