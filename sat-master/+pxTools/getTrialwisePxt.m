%% pxTools_getTrialwisePxt
% Generates probability distributions from the supplied timeseries
% data cell ('xtDataCell'), using the queried time points and parameters.
% Used for multiple-comparisions/extractions. Not optimial for single
% comparisions
%
% PREREQUSITE: xtDataCell has been processed by 'createXtStateMap.m'; to
% provide for signal levels for assigning discrete states
%
% INPUT PARAMETERS: 
%   xtDataCell : a {2, #Trials}; Each element of the first row contains a
%       structure with fields ('envelope', 'signalLevels'); each element
%       in the second row contains metadata for processing parameters of
%       the timeseries data
%   ppDataCell : (Optional) a {2, #Trials}; Each element of the first row 
%       contains a structure with fields ('time') ; elements in the second 
%       row contain metadata for processing parameters of point process Data. 
%       - Points are queried at time provided by {1,TRIAL#}(unit).time
%       - If passed, needs to have same number of columns as xtDataCell
%       - If not provided, script will evaluate pxt at ALL time points
%   [StartTrial#: EndTrial#] (Optional)
%       - If not provided, script will evaluate over all trials (columns)
%   [xt Channel Range] (Optional)
%       - Subindex of xtDataCell; if not provided, evaluate over all time
%       series data channels (struct rows)
%   [pp Channel Range] (Optional)
%       - Subindex of ppDataCell; if not provided, evaluate over all
%       point-process data channels (struct rows)
%
% OPTIONAL NAME-VALUE PAIRED ARGUMENTS
%   'xtDatafield': (character array)
%       - Field from xtDataCell containing time series data; 
%       - Default 'envelope'; 
%   'ppDataField': (character/string)
%       - Field from ppDataCell containining the time/event data
%       - Default 'time'
%   'pxNPoints': [#PointsPrior, #PointsPoint]
%       - Number of points to use relative to time index to collect state
%       over before (first val) or after (second val) the reference time
%       - If not provided, defaults to [20 20]; 
%   'pxFilter': [#States Width, #States Standard Deviation]
%       - Gaussian Filtering Parameters for smoothing prespike/postspike
%       distributions. 
%       - If set to [0,0], do not filter distributions; 
%       - Default: [0,0]; 
%   'pxShift': [Integer]
%       - Where the split between prespike and postspike distributions are
%       defined relative to reference time point (0); 
%       - Default = 1; (reference point terminal value of prespike dist)
%   'pxDelay': [Integer]
%       - Number of time bins between the end of 'prespike' and beginning
%       of 'postspike' distributions; 
%       - Default = 1; 
%
% OUTPUTS; 
%   pxt0Cell = N_XT x N_PP cell of appended prespike state distributions
%   pxt1Cell = N_XT x N_PP cell of appended postspike state distributions 
%   iXt0Cell = N_XT x N_PP cell of utilized prespike positional indices
%   iXt1Cell = N_XT x N_PP cell of utilized postspike positional indices
%   at0Cell  = N_XT x N_PP cell of raw prespike signal values
%   at1Cell  = N_XT x N_PP cell of raw postspike signal values

% 2.26.2024 - Patch for handling of single-spike trials. 

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

%TODO: Improve validation of argparse inputs

function [pxt0Cell, pxt1Cell, iXt0Cell, iXt1Cell, at0Cell, at1Cell] = getTrialwisePxt(xtDataStruct, ppDataStruct, varargin)
if ~exist('ppDataStruct', 'var') 
    ppDataStruct = []; 
end

expectTrList = 1:size(xtDataStruct,2); 
expectXtList = 1:length(xtDataStruct{1,1}); 
expectXtDataField = 'envelope'; 
expectPpDataField = 'times'; 

p = inputParser; 
addOptional(p, 'trList', expectTrList); 
addOptional(p, 'xtList', expectXtList); 
addOptional(p, 'ppList', inf); 
% -- 
addParameter(p, 'xtDataField', expectXtDataField);
addParameter(p, 'ppDataField', expectPpDataField); 
addParameter(p, 'pxNPoints', [20,20]); 
addParameter(p, 'pxFilter', [0,0]); 
addParameter(p, 'pxShift',  1); 
addParameter(p, 'pxDelay', 0); %this is z delay, not spike delay
parse(p, varargin{:}); 

pR = p.Results; 
%_____________
TR_LIST     = pR.trList; 
XT_LIST     = pR.xtList; 
MAX_XT = max(XT_LIST); 


if pR.ppList == inf
    if ~isempty(ppDataStruct)
        PP_LIST = 1:length(ppDataStruct{1,1});
    else
        PP_LIST = 0;
    end
else
    if strcmpi(pR.ppList, 'all') == 1
        PP_LIST = 1:length(ppDataStruct{1,1}); 
    else
        PP_LIST  = pR.ppList; %(or empty, if not passed)
    end
end
MAX_PP      = max(PP_LIST); 

XT_FIELD    = pR.xtDataField; 
PP_FIELD    = pR.ppDataField;  
%
PX_PX0_PTS  = pR.pxNPoints(1); 
PX_PX1_PTS  = pR.pxNPoints(2);
PX_FSM_WID  = pR.pxFilter(1);  
PX_FSM_STD  = pR.pxFilter(2); 
PX_NSHIFT   = pR.pxShift; 
PX_ZDELAY   = pR.pxDelay; 
    
%__ Initialize    
pxt0Cell = cell(1,MAX_XT); 
pxt1Cell = cell(1,MAX_XT); 
iXt0Cell = cell(1,MAX_XT); 
iXt1Cell = cell(1,MAX_XT); 
at0Cell  = cell(1,MAX_XT); 
at1Cell  = cell(1,MAX_XT); 

if nargout == 6
    PASS_SIGAMP  = 1; 
    PASS_INDICES = 1; 
elseif nargout == 4
    PASS_SIGAMP  = 0;
    PASS_INDICES = 1; 
else
    PASS_SIGAMP  = 0; 
    PASS_INDICES = 0; 
end
    
%// evaluate timeseries data at PP times

for tr=TR_LIST   
    pxt0Cell{1,tr} = cell(MAX_XT, MAX_PP); 
    pxt1Cell{1,tr} = cell(MAX_XT, MAX_PP); 
    for m=XT_LIST
        if PP_LIST == 0
            %// PP Data not passed; eval XT for all Points
            [px_t0, px_t1, iX_t0, iX_t1] = pxTools.getPxtFromXt(...
                xtDataStruct{1,tr}(m).(XT_FIELD),...
                'all' , xtDataStruct{1,tr}(m).signalLevels, ...
                [PX_PX0_PTS, PX_PX1_PTS],...
                PX_FSM_WID, PX_FSM_STD, ...
                PX_NSHIFT, PX_ZDELAY);         
            pxt0Cell{1,tr}{m,1} = px_t0; 
            pxt1Cell{1,tr}{m,1} = px_t1; 
            if PASS_INDICES
                iXt0Cell{1,tr}{m,1} = iX_t0; 
                iXt1Cell{1,tr}{m,1} = iX_t1; 
            end
            if PASS_SIGAMP
                at0Cell{1,tr}{m,1} = xtDataStruct{1,tr}(m).(XT_FIELD)(iX_t0); 
                at1Cell{1,tr}{m,1} = xtDataStruct{1,tr}(m).(XT_FIELD)(iX_t1); 
                %
                if (length(st) == 1) && (size(at0Cell{1,tr}{m,u},1) < PX_PX0_PTS)
                    at0Cell{1,tr}{m,u} = at0Cell{1,tr}{m,u}'; 
                end
                if (length(st) == 1) && (size(at1Cell{1,tr}{m,u},1) < PX_PX1_PTS)
                    at1Cell{1,tr}{m,u} = at1Cell{1,tr}{m,u}'; 
                end
            end
        else
            for u=PP_LIST
                st = ppDataStruct{1,tr}(u).(PP_FIELD); 
                conformedST = round(xtDataStruct{1,tr}(m).fs*st); 
                [px_t0, px_t1, iX_t0, iX_t1] = pxTools.getPxtFromXt(...
                    xtDataStruct{1,tr}(m).(XT_FIELD),...
                    conformedST , xtDataStruct{1,tr}(m).signalLevels, ...
                    [PX_PX0_PTS, PX_PX1_PTS],...
                    PX_FSM_WID, PX_FSM_STD, ...
                    PX_NSHIFT, PX_ZDELAY);                 
                %_____
                pxt0Cell{1,tr}{m,u} = px_t0; 
                pxt1Cell{1,tr}{m,u} = px_t1; 
                if PASS_INDICES
                    iXt0Cell{1,tr}{m,u} = iX_t0; 
                    iXt1Cell{1,tr}{m,u} = iX_t1; 
                end
                if PASS_SIGAMP
                    at0Cell{1,tr}{m,u} = xtDataStruct{1,tr}(m).(XT_FIELD)(iX_t0); 
                    at1Cell{1,tr}{m,u} = xtDataStruct{1,tr}(m).(XT_FIELD)(iX_t1); 
                    if (length(st) == 1) && (size(at0Cell{1,tr}{m,u},1) < PX_PX0_PTS)
                        at0Cell{1,tr}{m,u} = at0Cell{1,tr}{m,u}'; 
                    end
                    if (length(st) == 1) && (size(at1Cell{1,tr}{m,u},1) < PX_PX1_PTS)
                        at1Cell{1,tr}{m,u} = at1Cell{1,tr}{m,u}'; 
                    end
                end
            end
        end
    end
end

if nargout == 4
    at0Cell = []; 
    at1Cell = [];     
elseif nargout == 2    
    iXt0Cell = []; 
    iXt1Cell = [];    
    at0Cell = []; 
    at1Cell = [];    
end

end
