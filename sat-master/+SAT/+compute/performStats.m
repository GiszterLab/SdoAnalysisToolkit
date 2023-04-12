%% computeSdo.performStats
% Given the assembled 'sdo' structure, calculate the Knullback-Leibler
% Divergence (KLD) metrics from the Monte Carlo shuffled-spike and
% background null hypotheses. 
% Note that the column-sum of the joint SDO is the average pre-spike
% distribution, and the row-sum of the joint SDO is the average post-spike
% distribution; 
%
% PREREQUISITES: 
%   computeSdo.PopulateSDOArray()
%
% INPUT: 
%   'sdo' struct
% OUTPUT:
%   'sdo' structure matrix; statistics appended

% Trevor S.  Smith, 2022
% Drexel University College of Medicine

function sdo = performStats(sdo)
N_XT_CHANNELS = length(sdo); 
N_PP_CHANNELS = length(sdo(1).sdos); 

for m = 1:N_XT_CHANNELS
    for u = 1:N_PP_CHANNELS
        if isempty(sdo(m).shuffles{1,u}.SDOJointShuff)
            ISEMPTY = 1;
        else
            ISEMPTY = 0;
        end    
        %% spike v. background (common)
        
         %// distance of neuron to background
        [KNeuronBk, KPx0NeuronBk, KCondNeuronBk] = SAT.compute.KLDMeasures(...
            sdo(m).sdosJoint{u},...
            sdo(m).bkgrndJointSDO);        
        
        changeMeasureContSDO        = matTriangle_up_down_difference(sdo(m).sdos{u});
        
        %% N shuffles > 0
        if ~ISEMPTY
        
            meanJointShuffSDO = mean(sdo(m).shuffles{1,u}.SDOJointShuff,3);
            %_____

            %// distance of each spike-shuffled sdo from backgrnd SDO
            [KShuffBk, KPx0ShuffBk, KCondShuffBk] = SAT.compute.KLDMeasures(...
                sdo(m).shuffles{1,u}.SDOJointShuff,...
                sdo(m).bkgrndJointSDO); 
            %// distance of neuron sdo from mean of spike-shuffled SDO
            [KNeuronAvgShuff, KPx0NeuronAvgShuff, KCondAvgShuff] = SAT.compute.KLDMeasures(...
                sdo(m).sdosJoint{1,u},...
                meanJointShuffSDO); 
            %// distance of each spike-shuffled sdo from mean of shuffled SDO
            [KShuffAvgShuff, KPx0ShuffAvgShuff, KCondShuffAvgShuff] = SAT.compute.KLDMeasures(...
                sdo(m).shuffles{1,u}.SDOJointShuff,...
                meanJointShuffSDO); 
            %

            changeMeasureShuffContSDO   = matTriangle_up_down_difference(sdo(m).shuffles{u}.SDOShuff);
        else
            %// Dummy
            %meanJointShuffSDO   = []; 
            KShuffBk            = []; 
            KPx0ShuffBk         = [];
            KCondShuffBk        = []; 
            KNeuronAvgShuff     = []; 
            KPx0NeuronAvgShuff  = []; 
            KCondAvgShuff       = []; 
            KShuffAvgShuff      = []; 
            KPx0ShuffAvgShuff   = []; 
            KCondShuffAvgShuff  = []; 
            changeMeasureShuffContSDO = []; 
        end
        
        %_______
        %// Fill MAB Fields --> Rename these after correcting stats?
        sss = struct(); 
        %
        sss.changeMeasureContSDO        = changeMeasureContSDO; 
        sss.changeMeasureShuffContSDO   = changeMeasureShuffContSDO; 
        sss.KL2D_neuron_bk              = KNeuronBk; 
        sss.KL2D_shuff_bk               = KShuffBk; 
        sss.KLcurr_neuron_bk            = KPx0NeuronBk; 
        sss.KLcurr_shuff_bk             = KPx0ShuffBk; 
        sss.KLcond_neuron_bk            = KCondNeuronBk; 
        sss.KLcond_shuff_bk             = KCondShuffBk; 
        sss.KL2D_neuron_meanshuff       = KNeuronAvgShuff; 
        sss.KL2D_shuff_meanshuff        = KShuffAvgShuff; 
        sss.KLcurr_neuron_meanshuff     = KPx0NeuronAvgShuff; 
        sss.KLcurr_shuff_meanshuff      = KPx0ShuffAvgShuff; 
        sss.KLcond_neuron_meanshuff     = KCondAvgShuff; 
        sss.KLcond_shuff_meanshuff      = KCondShuffAvgShuff; 
        %sss.meanShuffSDO                = meanDeltaShuffSDO; 
        %sss.meanJointShuffSDO           = meanJointShuffSDO; 
        %___
        sdo(m).stats{1,u} = sss; 
    end
end

end