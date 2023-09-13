%% validate DataCells
% Having built the xtDataCell and the ppDataCell, ensure that the fields
% used in SDO analysis are well defined; Limited cell-structure correction.
%
% PREREQUISITES:
%   sdoAnalysis_ppDataCell_new()
%   sdoAnalysis_xtDataCell_new()
%
% SCANNED PROPERTIES
% 1) Structures have homogenous elements
% 2) All elements are fully defined; 
% 3) Orientation of various vectors are proper (row vectors preferred)
%
% PARAMETERS
%   xtDataCell: populated xtDataCell to validate for completeness
%   ppDataCell: populated ppDataCell to validate for completeness
%   FIX_FLAG  : [0/1] Toggle. If '1', attempt to conform matrixes, if
%       warnings or errors are detected. 
%
% OUTPUT
%   xtDataCell: xtDataCell with attempted fixes, if FIX_FLAG = 1; 
%   ppDataCell: ppDataCell with attempted fixes, if FIX_FLAG = 1; 
%
%   EXIT FLAG 
%       0 No Warnings or Errors Detected
%           'computeSDO' should run accurately
%       1 Warnings Detected 
%           'computeSDO' should run, but output may have errors
%       2 Critical Errors Detected
%           'computeSDO' will fail with non-fixed structures; attempted
%           fixes by this script should be validated by the investigator
%

% Trevor S Smith, 2022
% Drexel University College of Medicine

%TODO: Ensure cast spiketimes are within ranges matched by xtdatacell

function [xtDataCell, ppDataCell, exitFlag] = sdoAnalysis_validateDataCells(xtDataCell, ppDataCell, FIX_FLAG)
% TODO: 
%// ensure datastructure sizes are homogeneous; 

if ~exist('FIX_FLAG','var')
    FIX_FLAG = 0; 
end

exitFlag = 0; 

N_TR_XT_DC = size(xtDataCell,2); 
N_TR_PP_DC = size(ppDataCell,2); 

%% Check for homogeneity within dataCells
%// Or at least flagrant violation of it

nElemTrWiseXT = zeros(1,N_TR_XT_DC); 
nElemTrWisePP = zeros(1,N_TR_PP_DC); 
for tr=1:N_TR_XT_DC
    nElemTrWiseXT(tr) = length(xtDataCell{1,tr}); 
end
for tr=1:N_TR_PP_DC
    nElemTrWisePP(tr) = length(ppDataCell{1,tr}); 
end

if ~all(nElemTrWiseXT == nElemTrWiseXT(1))
    exitFlag = max(exitFlag, 2); 
    disp("WARNING: Number of times-series data fields not consistent across trials."); 
    %// This one is particularly bad, because we are missing a continous
    %data channel which will dillute the SDO
    % --> Easiest fix is just to trim data to minimum-defined vals. 
    if FIX_FLAG
        [maxVal, goodTr] = max(nElemTrWiseXT); 
        fixIdx = find(nElemTrWiseXT < maxVal); 
        for ft = fixIdx
            rows2add = find(~ismember(1:maxVal, 1:nElemTrWiseXT(ft))); 
            for row = rows2add
                % .. Copy name
                xtDataCell{1,ft}(row).envelope  = zeros(size(xtDataCell{1,ft}(1).envelope)); 
                xtDataCell{1,ft}(row).electrode = xtDataCell{1,goodTr}(row).electrode; 
                xtDataCell{1,ft}(row).fs        = xtDataCell{1,goodTr}(row).fs; 
                xtDataCell{1,ft}(row).times      = xtDataCell{1,ft}(1).times; 
            end
        end
    else
        %// Let user fix it
        return
    end
end
if ~all(nElemTrWisePP == nElemTrWisePP(1))
    exitFlag = max(exitFlag, 2); 
    disp("WARNING: Number of point-process data fields not consistent across trials."); 
   if FIX_FLAG
        [maxVal, goodTr] = max(nElemTrWisePP); 
        fixIdx = find(nElemTrWisePP < maxVal); 
        for ft = fixIdx
            rows2add = find(~ismember(1:maxVal, 1:nElemTrWisePP(ft))); 
            for row = rows2add
                % .. Copy name
                ppDataCell{1,ft}(row).electrode = ppDataCell{1,goodTr}(row).electrode; 
                ppDataCell{1,ft}(row).time      = [];
                ppDataCell{1,ft}(row).counts    = []; 
            end
        end
   else
       %// Let User Fix it
        return
   end
end

%% Check Relative Sizes

if N_TR_XT_DC ~= N_TR_PP_DC
    disp( "WARNING: Mismatch in number of trials between structures"); 
    exitFlag = max(exitFlag, 2);  
    if FIX_FLAG
        if N_TR_XT_DC > N_TR_PP_DC
            %// conform PP DC
            missingTrialIdx = find(~ismember(1:N_TR_XT_DC, 1:N_TR_PP_DC)); 
            nMissingTrials = length(missingTrialIdx); 
            N_PP_CH = length(ppDataCell{1,end}); 
            dummyCells = sdoAnalysis_ppDataCell_new(nMissingTrials, N_PP_CH); 
            new_ppDataCell = [ppDataCell, dummyCells]; 
            for d = missingTrialIdx
                for u = 1:N_PP_CH
                    new_ppDataCell{1,d}(u).electrode = new_ppDataCell{1,1}(u).electrode; 
                end
            end
            ppDataCell = new_ppDataCell; 
        else
            %// conform XT DC
            missingTrialIdx = find(~ismember(1:N_TR_PP_DC, 1:N_TR_XT_DC)); 
            nMissingTrials = length(missingTrialIdx); 
            N_XT_CH = length(xtDataCell{1,end}); 
            dummyCells = sdoAnalysis_xtDataCell_new(nMissingTrials, N_XT_CH); 
            new_xtDataCell = [xtDataCell, dummyCells]; 
            for d = missingTrialIdx
                for u = 1:N_XT_CH
                    new_xtDataCell{1,d}(u).electrode    = new_xtDataCell{1,1}(u).electrode; 
                    new_xtDataCell{1,d}(u).fs           = new_xtDataCell{1,1}(u).fs; 
                end
            end
            xtDataCell = new_xtDataCell; 
        end
        % --> Reshape the smaller as the bigger;
    else  
        return
    end
end

%% Validate Signal Lengths
% --> At this point, dataCells have been conformed to each other

N_TRIALS = size(xtDataCell,2); 
% __xtDataCell
N_XT_CH = length(xtDataCell{1,1}); 
N_PP_CH = length(ppDataCell{1,1}); 

for tr=1:N_TRIALS
    % ========= XT DATACELL ================
    % ______ Buffer Envelope Lengths; 
    sigLen = cellfun(@length, {xtDataCell{1,tr}.envelope}); 
    if ~all(sigLen == mode(sigLen))
        disp(strcat("WARNING: Mismatch in time series signal length on trial indexed at #", num2str(tr)));
        exitFlag = max(exitFlag, 1); 
        if FIX_FLAG
            %// append zeros to other vals; 
            maxLen = max(sigLen); 
            for m = 1:N_X_CH
                obsLen = length(xtDataCell{1,tr}(m).envelope); 
                if obsLen < maxLen
                    buffArr = zeros(1, maxLen); 
                    %// partial fill
                    buffArr(1:obsLen) = xtDataCell{1,tr}(m).envelope; 
                    xtDataCell{1,tr}(m).envelope = buffArr; 
                end
            end
        end
    end
    %_______ Ensure Vector Directions
    for m = 1:N_XT_CH
        for sf = {'envelope', 'times'}
            [xDim, yDim] = size(xtDataCell{1,tr}(m).(sf{1})); 
            if (xDim > 1) && (yDim == 1)
                %// Transpose; 
                xtDataCell{1,tr}(m).(sf{1}) = xtDataCell{1,tr}(m).(sf{1})'; 
            elseif (xDim > 1) && (yDim > 1)
                disp("Warning! Passed data is not 1xN format!"); 
                %// flatten
                xtDataCell{1,tr}(m).(sf{1}) = reshape(xtDataCell{1,tr}(m).(sf{1}), 1, []); 
            end
        end
    end 
    %_______ Validate fs
    fsVect = [xtDataCell{1,tr}.fs]; 
    if ~all(fsVect == fsVect(1))
        disp("WARNING: Frequency rate is not set homogeneous with data trials!")
        expectFs = mode(fsVect); 
        for m =1:N_XT_CH
            xtDataCell{1,tr}(m).fs = expectFs; 
        end
    end
    % ============= PP DATA CELL ============
    % ___ Validate 'counts'
    for u = 1:N_PP_CH
        if isempty(ppDataCell{1,tr}(m).counts)
            nSpikes = length(ppDataCell{1,tr}(m).time); 
            ppDataCell{1,tr}(m).counts = nSpikes; 
        end
    end

end

if exitFlag == 0
    disp("DataCells passed validation!"); 
end

if nargout == 0
    exitFlag = [];
    xtDataCell = [];
    ppDataCell = []; 
elseif nargout == 1
    xtDataCell = []; 
    ppDataCell = []; 
elseif nargout == 2
    exitFlag = []; 
end

%{
nCountsPerUnit = zeros(1, length(ppDataCell{1,1})); 
for tr=1:N_TRIALS
    nCountsPerUnit = nCountsPerUnit + [ppDataCell{1,1}.counts]; 
    
    
    %TODO: Whatever additional validation checks we require
    
end
%}
end