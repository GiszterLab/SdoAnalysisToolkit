function [stringOut] = underscores2spaces(stringIn)
%// for conforming names w/ underscores
strCell = strsplit(stringIn, '_'); 
stringOut = strCell{1}; 
for p=2:length(strCell) 
    stringOut = strcat(stringOut, " ", strCell{p}); 
end
end

