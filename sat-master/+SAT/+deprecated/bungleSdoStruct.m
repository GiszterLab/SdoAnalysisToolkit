%% Bungle
function sMat = bungleSdoStruct(obj)
   %// Method to 'reconstruct' a miniSDO array for the
   % common plotter method; 
   % __ >> Double-wrap a cell to make it look like a stacked 
    sMat = SAT.compute.sdoStruct_new(1,1); 
    sMat.signalType     = obj.xtChName; 
    sMat.neuronNames    = {obj.ppChName}; 
    sMat.levels         = obj.stateMapping; 
    sMat.sdosJoint      = {obj.sdoJoint}; 
    sMat.sdos           = {obj.sdo}; 
    sMat.bkgrndJointSDO = obj.sdoBkgrndJoint; 
    sMat.bkgrndSDO      = obj.sdoBkgrnd; 
    sMat.shuffles       = {obj.shuffles}; 
    sMat.stats          = {obj.stats};
    if ~isempty(obj.params)
        sMat.params         = obj.params; 
    else
        % __ for posterity__ (Redundant)
        sMat.params      = struct( ...
            'xt', obj.xtProperties, ...
            'pp', obj.ppProperties, ...
            'px', obj.pxProperties); 
    end
    sMat.stirpd         = {obj.stirpd}; 
end
%------------