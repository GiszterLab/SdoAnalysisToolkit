% Derive a vector of edges describing the relationship between signal
% amplitude and bins. 
%// Modular method of assigment

function signalLevels=getXtSignalLevels(X_MAX,X_MIN,N_BINS,XT_MAP_MODE)

esf = 1e-6; 

switch XT_MAP_MODE
    case 'linear'
        signalLevels = linspace(X_MIN, X_MAX, N_BINS+1);
    case 'log'
       min_y=log(max(X_MIN,esf));% if min_x<0.001 we set it to 0.001
       max_y=log(X_MAX);
       signalLevels = exp(linspace(min_y, max_y, N_BINS+1)); 
       
    case 'linearsigned'
        %// modification to permit negative values;
        absMax = max(abs([X_MAX, X_MIN])); 
        nStep = absMax/(N_BINS/2); 
        signalLevels = -absMax:nStep:absMax; 
       
    case 'logsigned'
       %// modification to permit negative values; 
       absMax   = max(abs([X_MAX, X_MIN])); 
       LAbsMax  = log(absMax); 
       LNStep   = LAbsMax/(N_BINS/2); 
       sigHalfLevels = exp(LNStep:LNStep:LAbsMax); 
       signalLevels = [-fliplr(sigHalfLevels), 0, sigHalfLevels];
end

end