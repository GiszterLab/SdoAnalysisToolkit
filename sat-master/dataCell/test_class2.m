

classdef test_class2 < handle
    properties
         data dataCell.primaryData
         pxTest 
    end
    
    methods
        % __ Test composed constructor
        function obj = test_class2( N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS = 1; 
                N_CHANNELS = 1; 
            end
            S = dataCell.primaryData('xtData', N_TRIALS, N_CHANNELS); 
            obj.data = S; 
            obj.pxTest = getPxTest(); 
            
            1; 
        end
        
        
    end
    
end

function pxTest = getPxTest()
    pxTest.prop1 = 0; 
    pxTest.prop2 = 1; 
    pxTest.prop3 = 'a'; 


end