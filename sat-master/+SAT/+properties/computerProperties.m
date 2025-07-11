%% 

% lightweight support class for sharing properties across structures; 
%
% --> Used by sdoComputer; Slaved to sdoMat; and sdoAnalyzer

% --> Can be expanded for additional properties, but is meant to operate
% in concert primarily with sdoComputer

classdef computerProperties < handle & matlab.mixin.Copyable
    properties (SetObservable)
        algorithm {mustBeMember(algorithm, {'v3', 'v5', 'v7'})} = 'v3';
        backgroundSubtraction = true; % This should be handled upstream. [or here]
        parallelCompute       = false; 
        obswise               = false; % Used for shuffles / multistacks
        lowMemory             = false; 
        verbose               = true; 
        % Trial Handling; 
        trialHandling         = 'combine' % Dummy;      
    end
    events
        algorithm_configChanged
        backgroundSubtraction_configChanged
        parallelCompute_configChanged
        obswise_configChanged
        lowMemory_configChanged
        verbose_configChanged
        trialHandling_configChanged
    end
    methods
        function obj = computerProperties()
            % EMPTY constructor
        end
        %% ----------------------------- %%
        % _____ Broadcasters ____ 
        function set.algorithm(obj, dat)
            obj.algorithm = dat; 
            obj.notifyChange("algorithm"); 
        end
        %
        function set.backgroundSubtraction(obj, LI)
            obj.backgroundSubtraction = LI; 
            obj.notifyChange("backgroundSubtraction");
        end
        %
        function set.parallelCompute(obj, LI)
            obj.parallelCompute = LI; 
            obj.notifyChange("parallelCompute");
        end
        % 
        function set.lowMemory(obj, LI)
            obj.lowMemory = LI; 
            obj.notifyChange("lowMemory"); 
        end
        %
        function set.verbose(obj, LI)
            obj.verbose = LI; 
            obj.notifyChange("verbose");
        end
        %
        function set.obswise(obj, LI)
            obj.obswise = LI; 
            obj.notifyChange("obswise");
        end
        %
        function set.trialHandling(obj, dat)
            obj.trialHandling = dat;
            obj.notifyChange("trialHandling"); 
        end
        %-------------------------------------
        %|| Notifier ||
        function notifyChange(obj, str)
            str2 = strcat(str, '_configChanged'); 
            notify(obj, str2);
        end
    end
    
end