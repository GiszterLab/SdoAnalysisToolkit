%% capCaseLine 
% utility macro from 
% string/char switch macro for capitalizing the first term

% Trevor S. Smith, 2022
% Drexel University College of Medicine


function [lineOut] = capitalizeLine(lineIn)

% --> Need to switch between Char and String typecasing

typ = class(lineIn); 

switch typ
    case 'string'
        %// need to split substring; 
        s0 = extractBefore(lineIn,2); 
        s1 = extractAfter(lineIn,2); 
        
        lineOut = strcat(upper(s0), s1); 
        
    case 'char'
        s0 = lineIn(1); 
        s1 = lineIn(2:end); 
        
        lineOut = [upper(s0) s1]; 
end

end