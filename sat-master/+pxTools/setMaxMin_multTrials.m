%% setMaxMin_
% Method for identifying the key minimum and maximum values across
% xtDataCell for assigning state values. 

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

function  xtDataCellmaxmin=setMaxMin_multTrials(xtData,segCell,xtMaxMode,varargin)

    if ~exist('xtMaxMode', 'var')
        xtMaxMode = 'xTrialxSeg'; 
    end

    p = inputParser; 
    addParameter(p, 'fieldname', 'envelope'); %now optional arg
    parse(p, varargin{:}); 
    pR = p.Results; 
    
    XT_DATA_FIELD = pR.fieldname; 

    if isempty(segCell)
        ALL_DATA = 1;
        %// ignore frequency and time segmenting
    else 
        ALL_DATA = 0; 
    end

    N_TRIALS = size(xtData,2);
    
    xtDataCellmaxmin = xtData; 
    switch xtMaxMode
        case 'xTrialxSeg'
            nXt = length(xtData{1});
            maxXt = ones(nXt, 1)*-inf; 
            minXt = ones(nXt, 1)*inf; 
            
            for i = 1:N_TRIALS
                xt = xtData{1,i};
                if ALL_DATA == 1
                    xtLen = length(xt(1).(XT_DATA_FIELD)); 
                else
                    Segm = segCell{i};
                end
                for m=1:nXt
                    if ALL_DATA == 1
                        [maxXtTrial, minXtTrial]=setMaxMin(xt(m).(pR.fieldname), 1, [1 xtLen]); 
                    else
                        [maxXtTrial, minXtTrial]=setMaxMin(xt(m).(pR.fieldname),xt(m).fs, Segm);
                    end
                    maxXt(m) = max([maxXtTrial maxXt(m)]); %update to greatest val
                    minXt(m) = min([minXtTrial minXt(m)]);
                end
            end
            for i = 1:N_TRIALS
                xt = xtData{1,i};
                for m=1:nXt
                    xt(m).max = maxXt(m);
                    xt(m).min = minXt(m);
                    xtDataCellmaxmin{1,i} = xt;
                end
            end
            
        case 'pTrialxSeg'
            for i = 1:N_TRIALS
                xt = xtData{1,i};
                nXt = length(xt);
                if ALL_DATA == 1
                    xtLen = length(xt(1).(pR.fieldname)); 
                else
                 Segm = segCell{i};                   
                end
                for m=1:nXt
                    if ALL_DATA == 1
                        [xtMax, xtMin] = setMaxMin(xt(m).(pR.fieldname), 1, [1 xtLen]); 
                    else
                        [xtMax, xtMin] = setMaxMin(xt(m).(pR.fieldname), xt(m).fs, Segm);
                    end
                    xt(m).max = xtMax;
                    xt(m).min= xtMin;
                end
                xtDataCellmaxmin{1,i} = xt;
            end
            
        case 'pTrial'
            for i = 1:N_TRIALS
                xt = xtData{1,i};
                nXt = length(xt);
                for m=1:nXt
                    [ xtMax, xtMin] = setMaxMin(xt(m).(pR.fieldname),1,[1 length(xt(m).(pR.fieldname))]);
                    %[ mmax, mmin] = setMaxMin(xt(m).envelope,1,[1 length(xt(m).envelope)]);
                    xt(m).max = xtMax;
                    xt(m).min= xtMin;
                end
                xtDataCellmaxmin{1,i} = xt;
            end
    end
end

%% Support Function

function [maxx, minx]=setMaxMin(x,fs,Seg)
% MAB Function
% Seg is in seconds each row is a segment
% fs is sampling frequency of x
numSeg=size(Seg,1);
maxx=-inf;
minx=+inf;
for m=1:numSeg
    startSamp=ceil(Seg(m,1)*fs);
    if startSamp<=0
        startSamp=1;
    end
    endSamp=floor(Seg(m,2)*fs);
    % 1.30.22 -TS modify to avoid over-shooting
    maxx=max([maxx x(startSamp:min(length(x),endSamp))]);
    minx=min([minx x(startSamp:min(length(x),endSamp))]);
end

end
