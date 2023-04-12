%% mergeSDOChunkArr
%Recompile the full SDO, if created chunkwise; 

%TODO: Is there a way to derive fieldtypes more intuitively?

function [sdo] = mergeSDOChunkArray(sdoChunkArr )
%// average common vals; append the other fields; 

[N_SUB_ROWS, N_SUB_COLS] = size(sdoChunkArr); 

N_XT_CHANNELS = 0; 
N_PP_CHANNELS = 0; 
MAX_XT_PER_CHUNK = 0; 
for row=1:N_SUB_ROWS
    N_XT_CHANNELS = N_XT_CHANNELS + length(sdoChunkArr{row,1}); 
    MAX_XT_PER_CHUNK = max(MAX_XT_PER_CHUNK, length(sdoChunkArr{row,1})); 
end
for col=1:N_SUB_COLS
    N_PP_CHANNELS = N_PP_CHANNELS + length(sdoChunkArr{1,col}(1).sdos); 
end

%totalNSpks = N_PP_CHANNELS; 
%MAX_PP_PER_CHUNK;

sdoFlat = computeSDO_sdo_new(N_XT_CHANNELS); 

% // fields to pass, average, and append
pssFields = {'signalType', 'levels', 'unit'}; 
avgFields = {'bkgrndJointSDO', 'bkgrndSDO'}; 
appFields = {'sdosJoint', 'sdos', 'neuronNames', 'shuffles', 'stats'}; 
%

for rowIDX = 1:N_SUB_ROWS
    for colIDX = 1:N_SUB_COLS
        %
        nSpks = length(sdoChunkArr{rowIDX,colIDX}(1).sdos); 
        %
        scf = nSpks/N_PP_CHANNELS; %scalar factor
        for ff = 1:length(sdoChunkArr{rowIDX,colIDX})
            if colIDX==1
                for p0 = 1:3
                    pssF = pssFields{p0};
                    sdoFlat(ff).(pssF) = sdoChunkArr{rowIDX,colIDX}(ff).(pssF); 
                end
            end
            for v0 = 1:2
                avgF = avgFields{v0};
                if colIDX == 1
                    sdoFlat(ff).(avgF) = sdoChunkArr{rowIDX,colIDX}(ff).(avgF)*scf;
                else
                    sdoFlat(ff).(avgF) = sdoFlat(ff).(avgF)+sdoChunkArr{rowIDX,colIDX}(ff).(avgF)*scf;
                end
            end
            for p0 = 1:4
                appF = appFields{p0};
                if colIDX == 1
                    sdoFlat(ff).(appF) = sdoChunkArr{rowIDX,colIDX}(ff).(appF); 
                else
                    sdoFlat(ff).(appF) = [sdoFlat(ff).(appF) sdoChunkArr{rowIDX,colIDX}(ff).(appF)]; 
                end
            end
        end
    end
    
    if rowIDX == 1
        sdo = sdoFlat; 
    elseif rowIDX > 1
        f0 = (rowIDX-1)*MAX_XT_PER_CHUNK+1; 
        f1 = min(rowIDX*MAX_XT_PER_CHUNK, N_XT_CHANNELS); 
        f_ref0 = f0 - (rowIDX-1)*MAX_XT_PER_CHUNK; 
        f_ref1 = f1 - (rowIDX-1)*MAX_XT_PER_CHUNK;
        sdo(f0:f1) = sdoFlat(f_ref0:f_ref1); 
    end
end

clear sdoFlat f0 f1 f_ref0 f_ref1 ff v0 p0 avgF appF

end