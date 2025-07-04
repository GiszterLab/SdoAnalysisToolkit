%% metadata Class
%
% Upgrade for V2 DataCells; here we will place this support class in the
% metadata field 


classdef BASE_metadata
    properties
        %% Here we have the common properties: 
        % Importing these over from the older superclass; 
        subjectName = []; 
        dataField = []; 
        %nTrials     {mustBeInteger} = 0; 
        %nChannels   {mustBeInteger} = 0; 
        sensor      = []; 
        fs          double {mustBeNonnegative} = 0 
        
    end
    
    
    
    
end