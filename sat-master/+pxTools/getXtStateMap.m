%% createXtStateMap
%Given a trialwise time series data structure, and a state-mapping method,
%output a signalLevel mapping for discretization; append to cell
%
% Used as a modular capacity to map state. xtData can then be converted
%using the statemapping with the MATLAB 'discretize' function
%
% PARAMETERS: 
%   xtData: Data Holder Cell to append
%   NBINS : [int]
%       - Number of 'states' to define from amplitude
%
% OPTIONAL NAME-VALUE PAIRS
%   'fieldname' 
%       - Field within xtDataCell to define states by
%       - Default is 'envelope'
%   'mapMethod'
%       - method of transforming amplitude ranges into state
%       - 'linear', 'log','linearsigned', 'logsigned'
%       - Default 'log
%   'maxMode'
%       - Normalization Method; 
%       - 'pTrial', 'xTrialxSeg', 'pTrialxSeg'
%       - Default 'xTrialxSeg'
%OUTPUT
%   sigLevelCell = nXt * ntr cell of sigMapping
%   xtData      = original structure, with vars appended; 

% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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


function [sigLevelCell, xtData] = getXtStateMap(xtData, N_BINS, varargin)
p = inputParser;
%expectedMethods = {'pTrial', 'pTrialxSeg', 'xTrialxSeg', 'logQuantile'};

addParameter(p, 'fieldname', 'envelope'); 
addParameter(p, 'maxMode', 'xTrialxSeg'); 
addParameter(p, 'mapMethod', 'log'); 

parse(p, varargin{:}); 
pR = p.Results;

XT_DATA_FIELD   = pR.fieldname;  
MAX_MODE        = pR.maxMode;  
MAP_METHOD      = pR.mapMethod; 
%_________

%Assume that the structure is homogeneous

%// segregate method by input type; 
% cell == element wise; array = all-at-once; struct = struct.field
clssType = class(xtData); 
switch clssType
    case 'struct'
        %// 1 trial, n-wise normalizations
        N_TRIALS = 1; 
        N_XT_CHANNELS = length(xtData); %height of struct; 
        %
        sigLevelCell = cell(N_XT_CHANNELS, N_TRIALS);
        %
        for iCh = 1:N_XT_CHANNELS
            xt = xtData(iCh).(p.fieldname); 
            sigLevels = pxTools.getXtSignalLevels(max(xt), min(xt), N_BINS, MAP_METHOD ); 
            sigLevelCell{iCh, N_TRIALS} = sigLevels; 
            xtData(iCh).signalLevels = sigLevels; 
        end
        %// Assign Params;     
    case 'cell'
        %// default structure; 
        N_TRIALS = size(xtData,2); %default row = trials
        %
        clssType2 = class(xtData{1,1}); 
        
        switch clssType2
            case 'double'
                N_XT_CHANNELS = size(xtData{1,1},1); 
                sigLevelCell = cell(N_XT_CHANNELS, N_TRIALS); 
                [maxXt, minXt] =  findMaxMinArrWise(xtData, MAX_MODE); 
                %// note that 'maxXt', and 'minXt' are nCh*nTr arrays
                for tr=1:N_TRIALS
                    for iCh = 1:N_XT_CHANNELS
                        sigLevels = pxTools.getXtSignalLevels(maxXt(iCh, tr), minXt(iCh, tr), N_BINS, MAP_METHOD); 
                        sigLevelCell{iCh, tr} = sigLevels; 
                        %// no appending to datacell, not supported by this
                        %type
                    end
                end
                
            case 'struct'
                %// default
                xtData = pxTools.setMaxMin_multTrials(xtData, [], MAX_MODE, 'fieldname', XT_DATA_FIELD); 
                N_XT_CHANNELS = length(xtData{1,1});
                %
                sigLevelCell = cell(N_XT_CHANNELS, N_TRIALS);
                %
                for tr = 1:N_TRIALS
                    for iCh = 1:N_XT_CHANNELS
                        sigLevels = pxTools.getXtSignalLevels(xtData{1,tr}(iCh).max, xtData{1,tr}(iCh).min, N_BINS, MAP_METHOD); 
                        sigLevelCell{iCh, tr} = sigLevels; 
                        xtData{1,tr}(iCh).signalLevels = sigLevels; 
                    end
                end
                
        end
        %// recast if necessary; 
        if size(xtData,1) == 1 
            xtBuff = cell(2, length(xtData)); 
            xtBuff(1, 1:end) = xtData; 
            xtData = xtBuff; 
        end
        %// writeout mapping vars
        for tr=1:N_TRIALS
            xtData{2,tr}.stateMapping = pR; 
        end
        
    case 'double'
        %// effectively just an array
        N_XT_CHANNELS = size(xtData, 1); 
        sigLevelCell = cell(1,N_XT_CHANNELS); 
        [maxXt, minXt] =  findMaxMinArrWise(xtData, MAX_MODE);  
        for iCh = 1:N_XT_CHANNELS
            sigLevels = pxTools.getXtSignalLevels(maxXt(iCh,1), minXt(iCh,1), N_BINS, MAP_METHOD); 
            sigLevelCell{iCh,1} = sigLevels; 
           %// no appending output; not supported by doubles array
        end
end
        
if nargout == 1
    xtData = []; 
end


end

%% Subfunctions; 

function [maxXt, minXt] =  findMaxMinArrWise(xtDataCell, MAX_MODE) 
%// Already have implicit assumption that the data are contained in an
%nCh*xt array, which may or may-not be wrapped into a cell; --> if I wrap
%into a cell from the beginning, then this is solved; 

if isa(xtDataCell, 'double')
    xtDataCell = {xtDataCell}; %convert to cell
end

NTRIALS = length(xtDataCell); 
N_XT_CHANNELS = size(xtDataCell{1},1); 

trWiseMax = zeros(N_XT_CHANNELS, NTRIALS); 
trWiseMin = zeros(N_XT_CHANNELS, NTRIALS); 

for iTr = 1:NTRIALS
    for iCh = 1:N_XT_CHANNELS
        trWiseMax(iCh,iTr) = max(xtDataCell{iTr}(iCh,:)); 
        trWiseMin(iCh,iTr) = min(xtDataCell{iTr}(iCh,:)); 
    end
end

%// now that we have data; assign trial min-max according to rule

switch MAX_MODE
    case 'xTrialxSeg'
        %// max over all trials; 
        maxXt = repmat(max(trWiseMax, [], 2), 1, NTRIALS); 
        minXt = repmat(min(trWiseMin, [], 2), 1, NTRIALS);        
    case {'pTrial', 'pTrialxSeg'}
        %// max val in individual trial
        maxXt = trWiseMax; 
        minXt = trWiseMin; 
        
end

end 

