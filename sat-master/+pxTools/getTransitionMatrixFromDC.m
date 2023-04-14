%% pxTools_getTransitionMatixFromDC
% Utility to preview the transition matrices given a set of parameters. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [mat] = getTransitionMatrixFromDC(xtData, XT_DC_CH_NO, varargin)
p = inputParser; 
addParameter(p, 'N_BINS', 20); 
addParameter(p, 'XT_MAP_MODE', 'log'); 
addParameter(p, 'PX0_DURA_MS', 10); 
addParameter(p, 'PX1_DURA_MS', 10); 
addParameter(p, 'PX_FSM_WID',  1);
addParameter(p, 'PX_FSM_STD', 1); 
addParameter(p, 'PX_NSHIFT' , 1);
addParameter(p, 'PX_ZDELAY' , 0); 
parse(p, varargin{:}); 
pR = p.Results; 

N_BINS      = pR.N_BINS; 
XT_MAP_MODE = pR.XT_MAP_MODE; 
PX0_DURA_MS = pR.PX0_DURA_MS; 
PX1_DURA_MS = pR.PX1_DURA_MS; 
PX_FSM_WID  = pR.PX_FSM_WID; 
PX_FSM_STD  = pR.PX_FSM_STD; 
PX_NSHIFT   = pR.PX_NSHIFT;  
PX_ZDELAY   = pR.PX_ZDELAY; 

%// Demo different state maps
[~, xtData] = pxTools.getXtStateMap(xtData, N_BINS, ... 
    'mapMode', XT_MAP_MODE); 

%[~, xtDataCell] = createXtStateMap(xtDataCell, N_BINS, ... 
%    'mapMode', XT_MAP_MODE); 
try
    XT_HZ = xtData{1,1}(XT_DC_CH_NO).fs; 
catch
    XT_HZ = 2000; 
end

N_PX0_PTS = round(PX0_DURA_MS*XT_HZ/1000); 
N_PX1_PTS = round(PX1_DURA_MS*XT_HZ/1000); 

trList = 1:size(xtData,2); 
[pxt0Cell, pxt1Cell] = pxTools.getTrialwisePxt(xtData, [], trList, XT_DC_CH_NO, ...
    'pxNPoints', [N_PX0_PTS,N_PX1_PTS], ...
    'pxFilter', [PX_FSM_WID,PX_FSM_STD ], ...
    'pxShift', PX_NSHIFT, ...
    'pxDelay', PX_ZDELAY); 


t0_0 = cellhcat(pxt0Cell); 
t0_1 = cellvcat(t0_0); 
t0_2 = cellhcat(t0_1); 

t1_0 = cellhcat(pxt1Cell); 
t1_1 = cellvcat(t1_0); 
t1_2 = cellhcat(t1_1); 

N_ELEMS = size(t0_2,2); 

arr = t1_2*t0_2'; 

mat = arr/N_ELEMS; 

end