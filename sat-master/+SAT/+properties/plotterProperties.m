%% SAT.properties.plotterProperties

% lightweight support class for sharing properties across plotters
%
% Can be used by various plotters in the toolkit. 

classdef plotterProperties < handle & matlab.mixin.Copyable
    properties (SetObservable)
        saveFig         = false
        saveFormat      {mustBeMember(saveFormat, {'png', 'svg'})} = 'png';  
        outputDirectory = []; 
        %
        lineSpec % Struct of fields. 
        %
        colorMap
    end
    properties (Dependent)
        nChannels 
    end
    
    events
        saveFig_configChanged
        saveFormat_configChanged
        outputDirectory_configChanged
    end
    methods
        function obj = plotterProperties()
            % EMPTY constructor

        end
        %% ----------------------------- %%
        function n = get.nChannels(obj)
            n = size(obj.colorMap, 1); 
        end
        % _____ Broadcasters ____ 
        function set.saveFig(obj, LI)
            obj.saveFig = LI; 
            obj.notifyChange("saveFig"); 
        end
        %
        function set.saveFormat(obj, dat)
            obj.backgroundSubtraction = dat; 
            obj.notifyChange("saveFormat");
        end
        %
        function set.outputDirectory(obj, dat)
            obj.parallelCompute = dat; 
            obj.notifyChange("outputDirectory");
        end
        %-------------------------------------
        %|| Notifier ||
        function notifyChange(obj, str)
            str2 = strcat(str, '_configChanged'); 
            notify(obj, str2);
        end
        %----------------------------------------------------
        function obj = makeLineSpec(obj, NAMES)
            if isempty(NAMES)
                NAMES = cell(1,7); for hh = 1:7; NAMES{hh} = strcat("H",num2str(hh)); end
            end
            obj.lineSpec = SAT.predict.assignPlotterProperties(NAMES);
        end
        %
        function obj = makeChannelMap(obj, N_COLORS, METHOD)
            arguments
                obj
                N_COLORS = 7; 
                METHOD {mustBeMember(METHOD, {'sin', 'linear', 'default', 'polar'})} = 'default';
            end
            obj.colorMap = rgb_colorGen(N_COLORS, METHOD); 
        end
        
    end
    
end