%% SAT.sdoUtils.fastShuff()
% Utility for more rapid shuffling, even if more indirect and difficult to maintain

% Trevor S. Smith, 2025

function shuffSDOMat = fastShuff(shuffSDOMat)
arguments
   shuffSDOMat sdoMat
end

if ~shuffSDOMat.eventShuffle.shuffledData
    shuffSDOMat.eventShuffle.shuffle(); 
end

% >> Pipe through deprecated; 

xtData = shuffSDOMat.xtData; %.data; 
ppData = shuffSDOMat.eventShuffle.getPpData(); 

xtData = shuffSDOMat.stateMapping.discretizeSignal(xtData); 

N_TRIALS    = xtData.nTrials;
N_XT_CH     = xtData.nChannels; 
N_PP_CH     = ppData.nChannels;

% _ Trialwise Handling not well Defined_ 
shuff_idx = ppData.getData; 

conformIX = @(x) round(x*xtData.fs); % anon func; 

shuff_idx = cellfun(conformIX, shuff_idx, 'uniformOutput', 0); 


maxT = max(xtData.trTimeLen); 

xi = 1:round(maxT*xtData.fs)+1; % superindex; 

xi0 = shuffSDOMat.x0Data.getIntervalIndicesRaw(xi, 'state'); 
xi1 = shuffSDOMat.x1Data.getIntervalIndicesRaw(xi, 'state'); 

xi0(xi0<1) = 1; 
xi1(xi1>xi(end)) = xi(end); 

nStates     = shuffSDOMat.nStates; 
nShuffles   = shuffSDOMat.eventShuffle.nShuffles; 

sdo_m_cell = cell(N_XT_CH, N_PP_CH);
sdo_l_cell = cell(N_XT_CH, N_PP_CH); 
sdo_ln_cell= cell(N_XT_CH, N_PP_CH); 

for m = 1:N_XT_CH
    for u = 1:N_PP_CH
        sdo_m_cell{m,u} = zeros(nStates, nStates, nShuffles); 
        sdo_l_cell{m,u} = zeros(nStates, nStates, nShuffles); 
        sdo_ln_cell{m,u}= zeros(nStates, nStates, nShuffles); 
    end
end

nEventsXTrial = shuffSDOMat.ppData.nTrialEvents;

tic; 
for tr = 1:N_TRIALS
    disp(strcat("Starting Trial #", num2str(tr), "/", num2str(N_TRIALS)) );
    nx = length(xtData.data{1,tr}(1).(xtData.dataField)); % interval lookup of IX;
    
    for m = 1:N_XT_CH
       
        xt = xtData.data{1,tr}(m).stateSignal; % Direct reference for speed; FRAGILE
        
        xi0_tr = xi0(:,1:nx); 
        xi1_tr = xi1(:,1:nx); 
        % __ 
        xi0_tr(xi0_tr<1) = 1; 
        xi1_tr(xi1_tr<1) = 1; 
        xi0_tr(xi0_tr>nx) = nx; 
        xi1_tr(xi1_tr>nx) = nx; 
        
        % manually samp; 
        xt0 = xt(xi0_tr); 
        xt1 = xt(xi1_tr); 
        
        % --> Conversion to p(x)
        %
        pxt0 = shuffSDOMat.px0Data.assignPxRaw( ...
            shuffSDOMat.stateMapping.subsample(tr,m), ...
            {xt0}); 
        
        pxt1 = shuffSDOMat.px0Data.assignPxRaw( ...
            shuffSDOMat.stateMapping.subsample(tr,m), ...
            {xt1}); 
        %
        
        for u = 1:N_PP_CH
            shuff_tr_idx = shuff_idx{u,tr}';
            px0_flat = pxt0{1}(:,shuff_tr_idx); 
            px1_flat = pxt1{1}(:,shuff_tr_idx);
            % TODO: Back-save the x0/x1 as well for stats testing
            
            if shuffSDOMat.config.backgroundSubtraction
                1; 
                % TODO: Add a predictive background step; 
                
            end
            %
            % this is a bit inefficient, but it's how sdo3/5/7 take input;
            px0_3 = reshape(px0_flat, shuffSDOMat.nStates, [], shuffSDOMat.eventShuffle.nShuffles);
            px1_3 = reshape(px1_flat, shuffSDOMat.nStates, [], shuffSDOMat.eventShuffle.nShuffles);
            %
                switch shuffSDOMat.config.algorithm
                    case 'v3'
                        %[L,M] = SAT.compute.sdo3(px0_flat(:,t0:t1), px1_flat(:,t0:t1), ...
                        [L,M] = SAT.compute.sdo3(px0_3, px1_3, ...
                            0, ....
                            'rescale', 0, ... 
                            'parallelCompute', shuffSDOMat.config.parallelCompute); 
                    case 'v5'
                         %[L,M] = SAT.compute.sdo5(px0_flat(:,t0:t1), px1_flat(:,t0:t1),
                        [L,M] = SAT.compute.sdo5(px0_3, px1_3, .....
                            0, ....
                            'rescale', 0, ...
                            'parallelCompute', shuffSDOMat.config.parallelCompute);                    
                    case 'v7'
                         %[L,M] = SAT.compute.sdo7(px0_flat(:,t0:t1), px1_flat(:,t0:t1), ...
                        [L,M] = SAT.compute.sdo7(px0_3, px1_3, ...
                            0, ....
                            'rescale', 0, ...
                            'parallelCompute', shuffSDOMat.config.parallelCompute);     
                end
        %}
            % Implicit add down across trials; 
            sdo_m_cell{m,u} = sdo_m_cell{m,u}+M;
            sdo_l_cell{m,u} = sdo_l_cell{m,u}+L; 
            %sdo_ln_cell{m,u} = sdo_ln_cell{m,u}+Ln;
        end
        disp(strcat("...Finished Ch ", num2str(m), "/", num2str(N_XT_CH)));
    end
end
toc; 

% Normalize; Write-out; 

sdo_ln_cell = cellfun(@SAT.sdoUtils.normsdo, sdo_l_cell, sdo_m_cell, 'UniformOutput',0); 

for m = 1:N_XT_CH
    for u = 1:N_PP_CH
        sdo_m_cell{m,u} = sdo_m_cell{m,u}/sum(nEventsXTrial(u,:)); 
        sdo_l_cell{m,u} = sdo_l_cell{m,u}/sum(nEventsXTrial(u,:));
        sdo_ln_cell{m,u}= sdo_ln_cell{m,u}/sum(nEventsXTrial(u,:));
        % 
        % __ DEAL ___
        shuffSDOMat.sdo(m,u).sdoMatrix ...
            = sdo_l_cell{m,u}; 
        shuffSDOMat.sdo(m,u).sdoMatrixNormed ...
            = sdo_ln_cell{m,u}; 
        shuffSDOMat.sdo(m,u).jointMatrix ...
            = sdo_m_cell{m,u};
    end
end

end