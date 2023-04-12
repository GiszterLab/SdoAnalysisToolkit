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


% Trevor S. Smith, 09.16.2022

%TODO: Improve validation of argparse inputs

function [pxt0Cell, pxt1Cell, iXt0Cell, iXt1Cell, at0Cell, at1Cell] = getTrialwisePxt(xtDataStruct, ppDataStruct, varargin)
if ~exist('ppDataStruct', 'var') 
    ppDataStruct = []; 
end

expectTrList = 1:size(xtDataStruct,2); 
expectXtList = 1:length(xtDataStruct{1,1}); 
expectXtDataField = 'envelope'; 
expectPpDataField = 'time'; 

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
pxt0Cell = cell(1,max(TR_LIST)); 
pxt1Cell = cell(1,max(TR_LIST)); 
iXt0Cell = cell(1,max(TR_LIST)); 
iXt1Cell = cell(1,max(TR_LIST)); 
at0Cell  = cell(1,max(TR_LIST)); 
at1Cell  = cell(1,max(TR_LIST)); 

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
    pxt0Cell{1,tr} = cell(max(XT_LIST), max(PP_LIST)); 
    pxt1Cell{1,tr} = cell(max(XT_LIST), max(PP_LIST)); 
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
