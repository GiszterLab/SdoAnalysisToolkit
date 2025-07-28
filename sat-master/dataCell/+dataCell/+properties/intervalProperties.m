%% dataCell.properties.intervalProperties
%
% lightweight support parameter class for intervals
% --> Used to sync and pass parameters for intervalSampling.
%
% meant to work in concert with 'intervalSampler; %Handle class to support
% inheritance

% Trevor S. Smith, 2025

classdef intervalProperties < handle & matlab.mixin.Copyable
    properties
        n_shift     = 0; 
        z_delay     = 0; 
        dura_ms     = 10; 
        fs          = 0; % x(t).fs; 
    end
    properties (Dependent)
        dura_nPoints
    end
    methods 
        % Constructor
        function obj = intervalProperties(N_SHIFT,Z_DELAY,DURA_MS)
            arguments
                N_SHIFT = 0; Z_DELAY = 0; DURA_MS = +10; 
            end
            obj.n_shift = N_SHIFT; 
            obj.z_delay = Z_DELAY;
            obj.dura_ms = DURA_MS; 
            % empty constructor; 
        end
        % ---- 
        function nPoints = get.dura_nPoints(obj)
            nPoints = ceil(obj.fs*obj.dura_ms/1000); % this allows nans; 
        end
        % --- 
        function LI = isChanged(obj, iP)
            arguments
                obj
                iP dataCell.properties.intervalProperties
            end
            sf = fieldnames(obj);
            for f = 1:length(sf)
                LI = (obj.(sf{f}) == iP.(sf{f}));  
                if LI == false
                    break
                end
            end
        end
        % ---- 
    end
    
end
