%% findMatchingStructRowFromString
%
%Macro for row-match indexing of struct field; used to find row indices for
%a 1xN structure, which correspond to a query. 
%
% pass in a struct, and field (of strings/characters), and find the unique
% vals, and produce an iterator for each unique type 'class', which can
% later be used as a indexing mask

% If SORT = 1; Use ascending numerical indexing for classIDX

%INPUTS: 
   % s      = stacked structure
   % sfield = (char/string) field which to eval for uniques; 
   % name   = if passed, will find matching rows w/ this element; 

   
%TODO: Need to comp a upgrade to this, which will permit rows which match
%multiple elements, or else rows which contain multiple elements to match,
%can be passed (otherwise, the resultant index list will not match the
%rownumbers of the struct, but rather the element positions of the struct

% -- TS 7.2.2022 -- 

function [classIDX, name] = findClassesFromStructFields(s, sfield, varargin) 
p = inputParser; 
addOptional(p, 'f', []); 
addParameter(p, 'sort', 1); 
parse(p, varargin{:})
pR = p.Results; 
f = pR.f; 
SORT = pR.sort; 
   
   % // because not a numeric, we can't just combine the uniques in a
   % stacked structure; use a for/while loop; 
   
    nameArr = {s(:).(sfield)}; 
    
    nNames = length(nameArr); 
    
    nmClss = class(nameArr{1}); 
    switch nmClss
        case 'string'
            nameArr0 = [nameArr{:}]; 
            nameArr = nameArr0; 
        case 'double'
            %// i.e. numerical; 
            % --> This will only work if we have a SINGLE value in the
            % array; 
            vect = cell2mat(nameArr); 
            
            name0 = unique(vect); 
            
            nClasses = length(name0); 
            
            classIDX = zeros(1,nNames); 
            name = cell(1,nClasses); 
            for ni = 1:nClasses
                n = name0(ni); %these are unique numbers; 
                ix = find(vect==n); 
                classIDX(ix) = n; 
                name{ni} = strcat('Class_', num2str(n)); 
                
            end
            
            
                1; 
            return
            
            %nameArr = cellfun(@unique, nameArr);

            
            
            
    end
    
    if isempty(f)
    %if ~exist('f', 'var')     
        name = unique(nameArr); 
    else
        name = {f};
    end
    classIDX = zeros(size(nameArr)); 
    %
    %{
    
    for n=1:length(name);
        clIDX = cellfun(@strcmpi, repelem(name(n), 1, length(s)), nameArr); 
        classIDX = classIDX+(clIDX*n);
    end
    %}
    %
    sLen = length(s); 
    
    % -- Possibly faster variant -- 
    for itt=1:sLen
        try
            classIDX(itt) = find(strcmpi(nameArr{itt}, name)==1); 
        end
    end
    %{
        n_idx    = 1; 
        classIDX = zeros(1,length(s)); 
        for itt= 1:length(s)
           if ~any(strcmpi(s(itt).(sfield), name));
               %if findNames == 1
               classIDX(itt) = n_idx; 
               name{n_idx} = s(itt).(sfield); 
               n_idx = n_idx+1; 
               %end
           else
               classIDX(itt) = find(strcmpi(s(itt).(sfield), name)==1); 
           end

        end
    %}
    
    %{
        else
        %// Single target hit
        name = {f};
        classIDX = cellfun(@strcmpi, repelem(name, 1, length(s)), s); 
    end
   %}
    if SORT
        %// We DONT have a guarrantee that elements are clustered, so
        %instead, we can only sort the first appearance of an element; 
        nGroups = length(name); 
        posArr = zeros(nGroups,1); 
        chGrp = cell(nGroups,1); 
        for g=1:nGroups
            chGrp{g}     = find(classIDX == g); 
            posArr(g)    = min(chGrp{g}); 
        end
        [~, sortIDX] = sort(posArr); 
        sortChGrp = chGrp(sortIDX); 

        classIDX2 = zeros(size(classIDX)); 
        name = name(sortIDX); 
        for g=1:nGroups
           classIDX2(sortChGrp{g}) = g; 
        end
        classIDX = classIDX2; 
    end
    
    
    
   if nargout == 1
       name0 = []; 
   end
   
end