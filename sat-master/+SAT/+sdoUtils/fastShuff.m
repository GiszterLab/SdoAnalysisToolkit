%% SAT.sdoUtils.fastShuff()
% Utility for more rapid shuffling, even if more indirect and difficult to maintain

% --> Here, it's probably easier to calc all, then index. 

% Trevor S. Smith, 2025

function shuffSDOMat = fastShuff(sat) %shuffSDOMat)
arguments
    sat SAT.analyzer
end
%{
arguments
   shuffSDOMat sdoMat2
end
%}

shuffSDOMat = sat.shuffleSDO; 

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

sdo_m_cell  = cellfun(@(~) zeros(nStates, nStates, nShuffles), sdo_m_cell, 'UniformOutput', 0); 
sdo_l_cell  = cellfun(@(~) zeros(nStates, nStates, nShuffles), sdo_l_cell, 'UniformOutput', 0); 
sdo_ln_cell = cellfun(@(~) zeros(nStates, nStates, nShuffles), sdo_l_cell, 'UniformOutput', 0); 

nEventsXTrial = shuffSDOMat.ppData.nTrialEvents;

USE_NEW = 1; 
tic; 
if USE_NEW ==1
    % This method isn't really any faster either. 
    bkg_sdo = copy(sat.backgroundSDO); 

    tMax = round(sat.backgroundSDO.xtData.fs * min(sat.backgroundSDO.xtData.trTimeLen)); 
    bkg_sdo.eventShuffle.random(N_TRIALS, 1, tMax, 'link', 'channels', 'type', 'all'); 
    func = @(x) x/sat.x0Config.fs-1/sat.x0Config.fs;
    bkg_sdo.eventShuffle.shuffleData = cellfun(func, bkg_sdo.eventShuffle.shuffleData, 'UniformOutput', 0); 
    %bkg_sdo.eventShuffle.
    bkg_sdo.ppData = bkg_sdo.eventShuffle.getPpData(); 
    bkg_sdo.drawIntervals(); 

    % This represents ALL Combinations (usually)
    bkg_sdo.x0Data.samplePrimaryData(bkg_sdo.xtData, ...
        'useTrials', 1:sat.nTrials, 'useChannels', 1:sat.nXtChannels);
    bkg_sdo.x1Data.samplePrimaryData(bkg_sdo.xtData, ...
        'useTrials', 1:sat.nTrials, 'useChannels', 1:sat.nXtChannels);

    bkg_sdo.px0Data.assignPx(bkg_sdo.stateMapping, bkg_sdo.x0Data); 
    bkg_sdo.px1Data.assignPx(bkg_sdo.stateMapping, bkg_sdo.x1Data);    

    % -- After cast; full throttle; 

    for tr = 1:N_TRIALS
        spk_ix_all = {sat.shuffleSDO.ppData.data{1, tr}(:).times}; 
        func = @(x) round(x * sat.x0Config.fs); 
        spk_ix_all = cellfun(func, spk_ix_all, 'UniformOutput', 0); 
        spk_ix_trans = cellfun(@transpose, spk_ix_all,'UniformOutput',0);
        for u = 1:N_PP_CH
            ix = spk_ix_trans{1,u}(:); 
            for m = 1:N_XT_CH
               %px0_flat = bkg_sdo.px0Data.data{m,tr}(:,spk_ix_trans{u}(:)); 
               %px1_flat = bkg_sdo.px1Data.data{m,tr}(:,spk_ix_trans{u}(:)); 
               px0_flat = bkg_sdo.px0Data.data{m,tr}(:,ix); 
               px1_flat = bkg_sdo.px1Data.data{m,tr}(:,ix); 
               %
               if shuffSDOMat.config.backgroundSubtraction
                    L0 = shuffSDOMat.sdo(m,u).backgroundSdo; 
                    pd_px1 = L0*px0_flat+px0_flat; 
                    %
                    px0_flat = pd_px1; % Reset; 
               end
               %--
                px0_3 = reshape(px0_flat, shuffSDOMat.nStates, [], shuffSDOMat.eventShuffle.nShuffles);
                px1_3 = reshape(px1_flat, shuffSDOMat.nStates, [], shuffSDOMat.eventShuffle.nShuffles);
                switch shuffSDOMat.config.algorithm
                    case 'v3'
                        [L,M] = SAT.compute.sdo3(px0_3, px1_3, ...
                            0, ....
                            'rescale', 0, ... 
                            'parallelCompute', shuffSDOMat.config.parallelCompute); 
                    case 'v5'
                        [L,M] = SAT.compute.sdo5(px0_3, px1_3, .....
                            0, ....
                            'rescale', 0, ...
                            'parallelCompute', shuffSDOMat.config.parallelCompute);                    
                    case 'v7'
                        [L,M] = SAT.compute.sdo7(px0_3, px1_3, ...
                            0, ....
                            'rescale', 0, ...
                            'parallelCompute', shuffSDOMat.config.parallelCompute);     
                end
                % Implicit add down across trials; 
                sdo_m_cell{m,u} = sdo_m_cell{m,u}+M;
                sdo_l_cell{m,u} = sdo_l_cell{m,u}+L; 
            end
            disp(strcat("...Finished Ch ", num2str(m), "/", num2str(N_XT_CH)));
        end
    end 
else
    %% --------------------------------- DIRECT CALL ----------------------
    
    % --- Precast
    shuff_idx = ppData.getData; 
    conformIX = @(x) round(x*xtData.fs); % anon func; 
    shuff_idx = cellfun(conformIX, shuff_idx, 'uniformOutput', 0); 
    
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
                    L0 = shuffSDOMat.sdo(m,u).backgroundSdo; 
                    pd_px1 = L0*px0_flat+px0_flat; 
                    %
                    px0_flat = pd_px1; % Reset; 
                end
                %
                % this is a bit inefficient, but it's how sdo3/5/7 take input;
                px0_3 = reshape(px0_flat, shuffSDOMat.nStates, [], shuffSDOMat.eventShuffle.nShuffles);
                px1_3 = reshape(px1_flat, shuffSDOMat.nStates, [], shuffSDOMat.eventShuffle.nShuffles);
                switch shuffSDOMat.config.algorithm
                    case 'v3'
                        [L,M] = SAT.compute.sdo3(px0_3, px1_3, ...
                            0, ....
                            'rescale', 0, ... 
                            'parallelCompute', shuffSDOMat.config.parallelCompute); 
                    case 'v5'
                        [L,M] = SAT.compute.sdo5(px0_3, px1_3, .....
                            0, ....
                            'rescale', 0, ...
                            'parallelCompute', shuffSDOMat.config.parallelCompute);                    
                    case 'v7'
                        [L,M] = SAT.compute.sdo7(px0_3, px1_3, ...
                            0, ....
                            'rescale', 0, ...
                            'parallelCompute', shuffSDOMat.config.parallelCompute);     
                end
            %}
                % Implicit add down across trials; 
                sdo_m_cell{m,u} = sdo_m_cell{m,u}+M;
                sdo_l_cell{m,u} = sdo_l_cell{m,u}+L; 
            end
            disp(strcat("...Finished Ch ", num2str(m), "/", num2str(N_XT_CH)));
        end
    end


end
toc; 
% Normalize; Write-out; 

for m = 1:N_XT_CH
    for u = 1:N_PP_CH
        sdo_m_cell{m,u} = sdo_m_cell{m,u}/sum(nEventsXTrial(u,:)); 
        sdo_l_cell{m,u} = sdo_l_cell{m,u}/sum(nEventsXTrial(u,:));
        sdo_ln_cell{m,u} = SAT.sdoUtils.normsdo(sdo_l_cell{m,u}, sdo_m_cell{m,u}); 
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