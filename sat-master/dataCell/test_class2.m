

classdef test_class2 < handle
    properties
         data dataCell.dependencies.primaryData
    end
    
    methods
        % __ Test composed constructor
        function obj = test_class2(N_TRIALS, N_CHANNELS)
            S = dataCell.dependencies.primaryData('xtData', N_TRIALS, N_CHANNELS); 
            
            
            1; 
        end
        
        
    end
    
end