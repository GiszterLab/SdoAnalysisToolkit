%% structmerge
%
% Support func for merging like-structs
%
% S1 = Struct 1
% S2 = Struct 2
% dir = direction of merge for like fields: 
%       - dir == 1 : Horizontal 
%       - dir == 2: Vertical

% Trevor Smith, 2025

function S12 = structmerge(S1,S2, dir)

if ~exist('dir', 'var')
    dir = 1; 
end


s1_fields = fieldnames(S1); 
s2_fields = fieldnames(S2); 

% Define new stuct from the intersect; 
sfields_12 = [s1_fields; s2_fields]; 

for f = 1:length(sfields_12)
    fn = sfields_12{f}; 
    
    if isfield(S1, fn) && isfield(S2,fn)
        if dir == 1
            %horzcat
            S12.(fn) = [S1.(fn), S2.(fn)]; 
        else
            %vertcat
            S12.(fn) = [S1.(fn); S2.(fn)]; 
        end
    elseif isfield(S1,fn)
        S12.(fn) = S1.(fn); 
    else
        S12.(fn) = S2.(fn);
    end

end