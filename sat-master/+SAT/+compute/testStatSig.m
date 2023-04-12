%% computeSDO_testStatSig
% Having calculated SDO significance w/ computeSDO_performstats,
% screen significant combinations for later plotting; 
% --> We can elementwise recreate these, as necessary

%// We use 2 types of stats: Sum-of-squared errors of the SDO (or
% derivative values) between the shuffles and unit, or Knullback-Leibler Divergence
% values between the topologies as proxies

%// In both cases, statistical significance is calculated as the percentile
%of the unit value vs. the bootstrapped values. 

%// because we calculating distance from a mean, all stats are 1-tailed
%(e.g. how far AWAY observed value is from mean-of-shuff)


%// Note that these are statistics of the SDO array itself, relative to shuffles
% not necessarily the utility of the predictions generated from the SDO. 

%Potential Combinations; 
% -1) coarse dpx (increase/decrease)
% -2) 2-D SSD Difference between Raw Arrays
% -3) KLD distribution of 1D metrics (i.e. px0, pxt); 
% -4) KLD distribuiton of 2D metrics (array; joint, diff)


% TS Written; Spun-off and adapted from MAB code


function [sdo] = testStatSig(sdo, SIG_PVAL, Z_SCORE)
if ~exist('Z_SCORE', 'var')
    Z_SCORE = 0; 
end


SIG_PCNT = 1-SIG_PVAL; 

N_XT_CHANNELS = length(sdo);       
N_PP_CHANNELS = length(sdo(1).stats); 

for m = 1:N_XT_CHANNELS
    for u = 1:N_PP_CHANNELS
        sdo(m).stats{u}.pVal = SIG_PVAL; 
        %__ 1D Coarse State bias; 
        %// Difference in state-wise increase/decrease; 
        unitVal     = sdo(m).stats{u}.changeMeasureContSDO; 
        shufVal     = sdo(m).stats{u}.changeMeasureShuffContSDO; 
        % --
        if isempty(shufVal)
            %// No shuffles detected; signficance testing impossible. 
            sdo(m).stats{u}.isSig_2D = 0; 
            sdo(m).stats{u}.isSig_Px0 = 0; 
            continue
        end

        %
        [isSig]=sigSSquaredCalculator(shufVal,unitVal,SIG_PVAL, Z_SCORE); 
        sdo(m).stats{u}.isSig_IncreaseDecrease = isSig;  
        %___ 2D Diff-SDO Topology Bias
        %// difference in diffential SDO topologies
        unitSDO     = sdo(m).sdos{u};
        
        shufSDO     = sdo(m).shuffles{u}.SDOShuff; 
        %
        %// '1' here is the z transform
        [isSig] = sigSSquaredCalculator(shufSDO, unitSDO, SIG_PVAL, Z_SCORE);
        sdo(m).stats{u}.isSig_2D = isSig; 
        
        %___ KLD 1D Differences (current state)
        % ||| State-at-spike (Px0)
        unitKLD     = sdo(m).stats{u}.KLcurr_neuron_meanshuff; 
        shufKLD     = sdo(m).stats{u}.KLcurr_shuff_meanshuff;  
        
        isSig = 0; 
        statThresh = dataAtPercentile(shufKLD, SIG_PCNT); 
        if unitKLD > statThresh
            isSig = 1; 
        end
        sdo(m).stats{u}.isSig_Px0 = isSig; 
        
        % ||| State-
        
        %... TODO fill in as many tests as desired 

    end
end

end
%% Subfunctions 


