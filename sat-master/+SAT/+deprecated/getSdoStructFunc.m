%% getSdostructFunc()

% Scratch wrapper for legacy struct w/ SAT.analyzer; 

% This is the original [V1] sdo core structure; 
% It is somewhat limited compared to new methods, but allows us 
% to use our original stats plugins. 

function [sdoS] = getSdoStructFunc(obj, useXtChannels, usePpChannels)
arguments
    obj     SAT.analyzer;
    useXtChannels = 1:obj.nXtChannels;
    usePpChannels = 1:obj.nPpChannels;
end
nXtChannels = length(useXtChannels);
nPpChannels = length(usePpChannels); 

sdoS = SAT.compute.sdoStruct_new(nXtChannels, nPpChannels); 

%-------------------------------------
for mi = 1:nXtChannels
    m = useXtChannels(mi); 
    %
    bk_px0 = obj.backgroundSDO.sdo(m,1).px0; 
    
    %---------------------
    sdoS(mi).signalType     = obj.unitSDO.xtSensor{m};
    sdoS(mi).levels         = obj.stateMapping.stateMapping(:,m,1);
    sdoS(mi).neuronNames    = obj.unitSDO.ppSensor(usePpChannels);
    sdoS(mi).bkgrndSDO      = obj.backgroundSDO.sdo(m,1).sdoMatrix;
    sdoS(mi).bkgrndJointSDO = diag(bk_px0)*obj.backgroundSDO.sdo(m,1).jointMatrix;
    
    sdoS(mi).unit        = '%';%= obj.unitSDO.sdo(
    1;
    stirpdCell = cell(1,nPpChannels);
    
    for uii = 1:nPpChannels
        u = usePpChannels(uii);
        %
        un_px0 = obj.unitSDO.sdo(1,m).px0; 
        sdoS(mi).sdos{uii}      = obj.unitSDO.sdo(m,u).sdoMatrix; 
        sdoS(mi).sdosJoint{uii} = diag(un_px0)*obj.unitSDO.sdo(m,u).jointMatrix; 
        %
        sdoS(mi).shuffles{uii}.SDOShuff ...
            = obj.shuffleSDO.sdo(m,u).sdoMatrix; 
        sdoS(mi).shuffles{uii}.SDOJointShuff ...
            = obj.shuffleSDO.sdo(m,u).jointMatrix; 
        %
        sdoS(m).shuffles{uii}.SDOShuff_mean = ...
            mean(sdoS(mi).shuffles{uii}.SDOShuff,3);
        sdoS(m).shuffles{uii}.SDOShuff_std	= ...
            std(sdoS(mi).shuffles{uii}.SDOShuff,[],3);
        sdoS(m).shuffles{uii}.SDOJointShuff_mean = ...
            mean(sdoS(mi).shuffles{uii}.SDOJointShuff,3); 
        sdoS(m).shuffles{uii}.SDOJointShuff_std = ...
            std(sdoS(mi).shuffles{uii}.SDOJointShuff,[],3); 
        %
        % TODO: Check this references the right xtdc; 
        stirpdCell{1,uii} = obj.unitSDO.getStirpd(1:obj.nTrials,uii);
    end
    sdoS(m).stirpd = stirpdCell; 
end

1;
end