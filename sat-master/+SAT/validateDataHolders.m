%% validate DataCells
% Having built the xtData and the ppData, ensure that the fields
% used in SDO analysis are well defined; Limited cell-structure correction.
%
% NOTE: Not recommended. Use 'xtData' and 'ppData' classes to avoid
% issues with validations.
%
% PREREQUISITES:
%   SAT.ppDataHolder_new()
%   SAT.xtDataHolder_new()
%
% SCANNED PROPERTIES
% 1) Structures have homogenous elements
% 2) All elements are fully defined; 
% 3) Orientation of various vectors are proper (row vectors preferred)
%
% PARAMETERS
%   xtData: populated xtData to validate for completeness
%   ppData: populated ppData to validate for completeness
%   FIX_FLAG  : [0/1] Toggle. If '1', attempt to conform matrixes, if
%       warnings or errors are detected. 
%
% OUTPUT
%   xtData: xtData with attempted fixes, if FIX_FLAG = 1; 
%   ppData: ppData with attempted fixes, if FIX_FLAG = 1; 
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

%_______________________________________
% Copyright (C) 2023 Trevor S. Smith
% Drexel University College of Medicine
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%__________________________________________


%TODO: Ensure cast spiketimes are within ranges matched by xtData

function [xtData, ppData, exitFlag] = validateDataHolders(xtData, ppData, FIX_FLAG)
% TODO: 
%// ensure datastructure sizes are homogeneous; 

if ~exist('FIX_FLAG','var')
    FIX_FLAG = 0; 
end

exitFlag = 0; 

N_TR_XT_DC = size(xtData,2); 
N_TR_PP_DC = size(ppData,2); 

%% Check for homogeneity within dataCells
%// Or at least flagrant violation of it

nElemTrWiseXT = zeros(1,N_TR_XT_DC); 
nElemTrWisePP = zeros(1,N_TR_PP_DC); 
for tr=1:N_TR_XT_DC
    nElemTrWiseXT(tr) = length(xtData{1,tr}); 
end
for tr=1:N_TR_PP_DC
    nElemTrWisePP(tr) = length(ppData{1,tr}); 
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
                xtData{1,ft}(row).envelope  = zeros(size(xtData{1,ft}(1).envelope)); 
                xtData{1,ft}(row).electrode = xtData{1,goodTr}(row).electrode; 
                xtData{1,ft}(row).fs        = xtData{1,goodTr}(row).fs; 
                xtData{1,ft}(row).times      = xtData{1,ft}(1).times; 
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
                ppData{1,ft}(row).electrode = ppData{1,goodTr}(row).electrode; 
                ppData{1,ft}(row).time      = [];
                ppData{1,ft}(row).counts    = []; 
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
            N_PP_CH = length(ppData{1,end}); 
            dummyCells = SAT.ppDataHolder_new(nMissingTrials, N_PP_CH); 
            %dummyCells = sdoAnalysis_ppData_new(nMissingTrials, N_PP_CH); 
            new_ppData = [ppData, dummyCells]; 
            for d = missingTrialIdx
                for u = 1:N_PP_CH
                    new_ppData{1,d}(u).electrode = new_ppData{1,1}(u).electrode; 
                end
            end
            ppData = new_ppData; 
        else
            %// conform XT DC
            missingTrialIdx = find(~ismember(1:N_TR_PP_DC, 1:N_TR_XT_DC)); 
            nMissingTrials = length(missingTrialIdx); 
            N_XT_CH = length(xtData{1,end}); 
            dummyCells = SAT.xtDataHolder_new(nMissingTrials, N_XT_CH);
            %dummyCells = sdoAnalysis_xtData_new(nMissingTrials, N_XT_CH); 
            new_xtData = [xtData, dummyCells]; 
            for d = missingTrialIdx
                for u = 1:N_XT_CH
                    new_xtData{1,d}(u).electrode    = new_xtData{1,1}(u).electrode; 
                    new_xtData{1,d}(u).fs           = new_xtData{1,1}(u).fs; 
                end
            end
            xtData = new_xtData; 
        end
        % --> Reshape the smaller as the bigger;
    else  
        return
    end
end

%% Validate Signal Lengths
% --> At this point, dataCells have been conformed to each other

N_TRIALS = size(xtData,2); 
% __xtData
N_XT_CH = length(xtData{1,1}); 
N_PP_CH = length(ppData{1,1}); 

for tr=1:N_TRIALS
    % ========= XT DATACELL ================
    % ______ Buffer Envelope Lengths; 
    sigLen = cellfun(@length, {xtData{1,tr}.envelope}); 
    if ~all(sigLen == mode(sigLen))
        disp(strcat("WARNING: Mismatch in time series signal length on trial indexed at #", num2str(tr)));
        exitFlag = max(exitFlag, 1); 
        if FIX_FLAG
            %// append zeros to other vals; 
            maxLen = max(sigLen); 
            for m = 1:N_XT_CH
                obsLen = length(xtData{1,tr}(m).envelope); 
                if obsLen < maxLen
                    buffArr = zeros(1, maxLen); 
                    %// partial fill
                    buffArr(1:obsLen) = xtData{1,tr}(m).envelope; 
                    xtData{1,tr}(m).envelope = buffArr; 
                end
            end
        end
    end
    %_______ Ensure Vector Directions
    for m = 1:N_XT_CH
        for sf = {'envelope', 'times'}
            [xDim, yDim] = size(xtData{1,tr}(m).(sf{1})); 
            if (xDim > 1) && (yDim == 1)
                %// Transpose; 
                xtData{1,tr}(m).(sf{1}) = xtData{1,tr}(m).(sf{1})'; 
            elseif (xDim > 1) && (yDim > 1)
                disp("Warning! Passed data is not 1xN format!"); 
                %// flatten
                xtData{1,tr}(m).(sf{1}) = reshape(xtData{1,tr}(m).(sf{1}), 1, []); 
            end
        end
    end 
    %_______ Validate fs
    fsVect = [xtData{1,tr}.fs]; 
    if ~all(fsVect == fsVect(1))
        disp("WARNING: Frequency rate is not set homogeneous with data trials!")
        expectFs = mode(fsVect); 
        for m =1:N_XT_CH
            xtData{1,tr}(m).fs = expectFs; 
        end
    end
    % ============= PP DATA CELL ============
    % ___ Validate 'counts'

    % TS Patch for legacy data; 
    
    if isfield(ppData{1,1}, 'nEvents')
        PPCOUNTFIELD = 'nEvents'; 
    else
        PPCOUNTFIELD = 'counts';
    end

    for u = 1:N_PP_CH
        if isempty(ppData{1,tr}(m).(PPCOUNTFIELD))
        %if isempty(ppData{1,tr}(m).counts)
            nSpikes = length(ppData{1,tr}(m).time); 
            ppData{1,tr}(m).counts = nSpikes; 
        end
    end

end

if exitFlag == 0
    disp("DataCells passed validation!"); 
end

if nargout == 0
    exitFlag = [];
    xtData = [];
    ppData = []; 
elseif nargout == 1
    xtData = []; 
    ppData = []; 
elseif nargout == 2
    exitFlag = []; 
end

%{
nCountsPerUnit = zeros(1, length(ppData{1,1})); 
for tr=1:N_TRIALS
    nCountsPerUnit = nCountsPerUnit + [ppData{1,1}.counts]; 
    
    
    %TODO: Whatever additional validation checks we require
    
end
%}
end