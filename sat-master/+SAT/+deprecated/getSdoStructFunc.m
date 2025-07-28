%% getSdostructFunc()
%
% DEPRECATED
%
% Wrapper for legacy struct w/ SAT.analyzer; 
%
% This is the original [V1] sdo core structure; 
% It is somewhat limited compared to new methods, but allows us 
% to use our original stats plugins. This is a restricted cast; here we
% only make what we need.

function [sdoS] = getSdoStructFunc(obj, useXtChannels, usePpChannels, vars)
arguments
    obj     SAT.analyzer;
    useXtChannels = 1:obj.nXtChannels;
    usePpChannels = 1:obj.nPpChannels;
    vars.performStats = 1; 
end
nXtChannels = max(useXtChannels); 
nPpChannels = max(usePpChannels); 

sdoS = SAT.compute.sdoStruct_new(nXtChannels, nPpChannels); 

spkCounts = sum(obj.unitSDO.ppData.nTrialEvents,2); %[U,1]; 

%-------------------------------------
for mi = 1:length(useXtChannels)
    m = useXtChannels(mi); 
    %---------------------
    sdoS(m).signalType     = obj.unitSDO.xtSensor{m};
    sdoS(m).levels         = obj.stateMapping.stateMapping(:,m,1);
    sdoS(m).neuronNames    = obj.unitSDO.ppSensor;
    sdoS(m).bkgrndSDO      = obj.backgroundSDO.sdo(m,1).sdoMatrix;
    sdoS(m).bkgrndJointSDO = obj.backgroundSDO.sdo(m,1).jointMatrix;
    %
    sdoS(m).unit        = '%';
    stirpdCell = cell(1,nPpChannels);
    
    for uii = 1:length(usePpChannels)%nPpChannels
        u = usePpChannels(uii);
        %
        sdoS(m).sdos{u}      = obj.unitSDO.sdo(m,u).sdoMatrix; 
        sdoS(m).sdosJoint{u} = obj.unitSDO.sdo(m,u).jointMatrix; 
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
        stirpdCell{1,u} = obj.unitSDO.getStirpd(1:obj.nTrials,m,u);
        %
        % __ Paste in
        sdoS(m).stats{u}.nEvents    = spkCounts(u);
        sdoS(m).stats{u}.pVal       = obj.pValue; 
    end
    sdoS(m).stirpd = stirpdCell; 
end

if vars.performStats
    sdoS = SAT.compute.performStats(sdoS, useXtChannels, usePpChannels); 
end

end