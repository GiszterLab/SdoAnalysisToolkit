
function plot_STA(xtdc, ppdc, XT_CH_NO, PP_CH_NO, vars)
arguments
    xtdc
    ppdc
    XT_CH_NO = 1; 
    PP_CH_NO = 1; 
    vars.datafield = 'raw'
end

nPPCH = numel(PP_CH_NO); 
nXTCH = numel(XT_CH_NO); 

N_T0_PTS = 40; 
N_T1_PTS = 40; 

USE_TRIALS = 1:xtdc.nTrials; 

xtData = xtdc.data; 
ppData = ppdc.data; 

%DATA_FIELD = 'envelope'; 
%DATA_FIELD = 'raw'; 
DATA_FIELD = vars.datafield; 

tVect = (-N_T0_PTS+1:N_T1_PTS) /xtdc.fs*1000; 

[idx0_Cell, idx1_Cell] = getPerieventIndices(ppdc, USE_TRIALS, PP_CH_NO, ...
    't0_nPoints', N_T0_PTS, 't1_nPoints', N_T1_PTS, 'fs', xtdc.fs); 


staArr = cell(nPPCH, nXTCH); 

for c = 1:nPPCH
    idx0 = idx0_Cell{c}; 
    idx1 = idx1_Cell{c}; 
    
    idx = [idx0;idx1]; 

    xt = xtdc.getValuesAtIndices(idx, 'useChannels', XT_CH_NO, 'dataField', DATA_FIELD); 
    
    staArr(c,:) = xt; 
end

for c = 1:nPPCH
    for r = 1:nXTCH
        % Baseline level; 
        staArr{c,r} = staArr{c,r} - mean(staArr{c,r}(1:5,:)); 
        
    end
end


figure;
%tiledlayout(nPPCH, nXTCH); 
tiledlayout(nXTCH,nPPCH); 

for r = 1:nXTCH
    for c = 1:nPPCH
        nexttile; 
        plot(tVect, mean(staArr{c,r},2), 'color', 'k'); 
        hold on; plot(tVect, median(staArr{c,r},2), 'b--'); 
    end
end





1; 


end