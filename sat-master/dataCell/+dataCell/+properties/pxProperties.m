%% dataCell.properties.pxProperties (OOP) V2
%
% Support class for pxParameters. This class is used to sync and move
% params between composite data structures; 
%
% Trevor S. Smith

classdef pxProperties < handle & matlab.mixin.Copyable
    properties
        weighting {mustBeMember(weighting, {'equal'})} = 'equal';
        % __ For (Gaussian) filter Kernel______
        G_smoothFWidth_Pts = 0; 
        G_smoothFStdev_Pts = 0;             
    end
    methods
        % // Empty Constructor;
        function obj = pxProperties()
            obj.weighting           = 'equal';
            obj.G_smoothFWidth_Pts  = 0;
            obj.G_smoothFStdev_Pts  = 0; 
        end
        %-------
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
    %
end