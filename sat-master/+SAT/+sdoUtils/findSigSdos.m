%% Screen SDOs (struct) for significance
% Simple utility to screen the 'sdo' struct for particular spike-triggered
% SDOs which are demonstrate significance on at least SIG_THRESH tests. 
%
% PREREQUISITE: 
%   computeSDO_testStatSig()
%
% INPUT: 
%   sdo - structure
%   SIG_THRESH: 
%       - Integer. Minimum number of significant tests to pass screen.
%       [0-3]. 
% OUTPUT: 
%   lookupStruct - structure containing the row and column indices, and
%       channel  names of screened SDOs, along with their signifcance
%       score.
%

% Trevor S. Smith, 2022
% Drexel University College of Medicine

% TODO: Add in functionality for multiple SDOs? 

function [lookupStruct]= findSigSdos(sdo, SIG_THRESH)
%// Keep in mind, may need to eventually scan across MULTIPLE 'sdo'
%structures, to back-compile

if ~exist('SIG_THRESH', 'var')
   SIG_THRESH = 0; 
end

N_PP_CHANNELS   = length(sdo(1).sdos); %numberNeurons
N_XT_CHANNELS   = length(sdo); %number EMG

%// Buffer cell to hold the data/analysis
lookupCell = cell(N_PP_CHANNELS*N_XT_CHANNELS,5); 
%iterate across all units, across all muscles (m1u1, m1u2, m1u3... m2u1..)

sfields     = fields(sdo(1).stats{1}); 
sig_sfields = sfields(contains(sfields, 'isSig')); 

for m = 1:N_XT_CHANNELS 
    for u =1:N_PP_CHANNELS
        ypos = (m-1)*N_PP_CHANNELS+u; 
        lookupCell{ypos,1} = m; 
        lookupCell{ypos,2} = u; 
        %// Rip names
        lookupCell{ypos,3} = sdo(m).signalType; 
        lookupCell{ypos,4} = sdo(m).neuronNames{u}; 
        %// Sum Significance (score column 3)
        score = 0; 
        for ii = 1:length(sig_sfields)
            score = score + sdo(m).stats{u}.(sig_sfields{ii}); 
        end
        lookupCell{ypos,5} = score; 
    end
end    

lkupScore = cell2mat(lookupCell(:,5)); 

LI = find(lkupScore >= SIG_THRESH); 

if ~ isempty(LI) 
    lookupCell = lookupCell(LI, :); 
    lookupStruct = cell2struct(...
        lookupCell, {..., 
        'xtChannelNo', ...
        'ppChannelNo', ...
        'xtChannelID', ...
        'ppChannelID', ...
        'nSigValues' ...
        }, 2);     
else
    lookupStruct = []; 
end

end