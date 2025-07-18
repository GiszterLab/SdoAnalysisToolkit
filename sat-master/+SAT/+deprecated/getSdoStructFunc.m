%% getSdostructFunc()
%
% DEPRECATED
%
% Scratch wrapper for legacy struct w/ SAT.analyzer; 
%
% This is the original [V1] sdo core structure; 
% It is somewhat limited compared to new methods, but allows us 
% to use our original stats plugins. 

% --> Restricted cast; only make what we need; 

function [sdoS] = getSdoStructFunc(obj, useXtChannels, usePpChannels)
arguments
    obj     SAT.analyzer;
    useXtChannels = 1:obj.nXtChannels;
    usePpChannels = 1:obj.nPpChannels;
end
%nXtChannels = length(useXtChannels);
%nPpChannels = length(usePpChannels); 
nXtChannels = max(useXtChannels); 
nPpChannels = max(usePpChannels); 

sdoS = SAT.compute.sdoStruct_new(nXtChannels, nPpChannels); 

%-------------------------------------
for mi = 1:length(useXtChannels)
%for mi = 1:nXtChannels
    m = useXtChannels(mi); 
    %
    bk_px0 = obj.backgroundSDO.sdo(m,1).px0; 
    
    %---------------------
    sdoS(m).signalType     = obj.unitSDO.xtSensor{m};
    sdoS(m).levels         = obj.stateMapping.stateMapping(:,m,1);
    sdoS(m).neuronNames    = obj.unitSDO.ppSensor;
    sdoS(m).bkgrndSDO      = obj.backgroundSDO.sdo(m,1).sdoMatrix;
    sdoS(m).bkgrndJointSDO = diag(bk_px0)*obj.backgroundSDO.sdo(m,1).jointMatrix;
    
    sdoS(m).unit        = '%';
    stirpdCell = cell(1,nPpChannels);
    
    for uii = 1:length(obj.nPpChannels)%nPpChannels
        u = usePpChannels(uii);
        %
        un_px0 = obj.unitSDO.sdo(1,m).px0; % trial 1
        sdoS(m).sdos{u}      = obj.unitSDO.sdo(m,u).sdoMatrix; 
        sdoS(m).sdosJoint{u} = diag(un_px0)*obj.unitSDO.sdo(m,u).jointMatrix; 
        %
        sdoS(m).shuffles{u}.SDOShuff ...
            = obj.shuffleSDO.sdo(m,u).sdoMatrix; 
        sdoS(m).shuffles{u}.SDOJointShuff ...
            = obj.shuffleSDO.sdo(m,u).jointMatrix; 
        %
        sdoS(m).shuffles{u}.SDOShuff_mean = ...
            mean(sdoS(m).shuffles{u}.SDOShuff,3);
        sdoS(m).shuffles{u}.SDOShuff_std	= ...
            std(sdoS(m).shuffles{u}.SDOShuff,[],3);
        sdoS(m).shuffles{u}.SDOJointShuff_mean = ...
            mean(sdoS(m).shuffles{u}.SDOJointShuff,3); 
        sdoS(m).shuffles{u}.SDOJointShuff_std = ...
            std(sdoS(m).shuffles{u}.SDOJointShuff,[],3); 
        %
        % TODO: Check this references the right xtdc; 
        stirpdCell{1,u} = obj.unitSDO.getStirpd(1:obj.nTrials,u);
    end
    sdoS(m).stirpd = stirpdCell; 
end

1;
end