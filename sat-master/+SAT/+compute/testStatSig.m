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

%_______________________________________
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
%__________________________________________

function [sdoStruct] = testStatSig(sdoStruct, SIG_PVAL, Z_SCORE)
if ~exist('Z_SCORE', 'var')
    Z_SCORE = 0; 
end

SIG_PCNT = 1-SIG_PVAL; 

N_XT_CHANNELS = length(sdoStruct);       
N_PP_CHANNELS = length(sdoStruct(1).stats); 

fit_dist = 0; % [1 uses pdfs, but fits are not guaranteed to be normal];  

for m = 1:N_XT_CHANNELS
    for u = 1:N_PP_CHANNELS
        sdoStruct(m).stats{u}.pVal = SIG_PVAL; 
        % ___ Redux for new comparisons (03.20.2024); 
        % --> We compare Unit, MeanShuff, Bkgnd vs. Shuff for tStat    
        ss = sdoStruct(m).stats{u}.comparisons; 

        %__ 1D Coarse State bias; 
        %// Difference in state-wise increase/decrease;

        % __ PUT TESTS HERE:: 
        % Calculate an internal distribution of potential outcomes
        % from shuffle and test background and unit SDOs
        % for significiant deviation from these; 
        testArr = { ... 
            'kld_px0_raw', ...
            'kld2_px1px0_px0Normed', ...
            'sse_sdoMat_px0Normed', ...
            'sse_px1px0_px0Normed', ...
            'se_upDown_xWise_raw', ...
            'sse_upDown_raw'}; 
        %
        nTests = length(testArr); 

        H = cell2struct(repmat({0}, nTests,1), testArr); 

        H_Bkgd = H; 
        H_Unit = H; 
        for t = 1:nTests
            test = testArr{t}; 
            shuff_stat  = permute(ss.Shuff_v_MeanShuff.(test), [2,3,1]); %flatten
            unit_stat   = ss.Unit_v_MeanShuff.(test);      
            bkgd_stat   = ss.Bkgd_v_MeanShuff.(test); 
            %___ P-Value bonferroni correction for statewise tests; 
            nTestStates = size(shuff_stat,1); 
            bonFerrpVal = SIG_PVAL/nTestStates;
            % ___ All tested values are scalar (distances), and hence
            % should be fit against a half-normal distribution, assuming
            % sig stat is -greater- than distribution

            % __>> For multi-comps, need to through in another for-loop 
            for x = 1:nTestStates
                critVal = inf*ones(1, nTestStates); 
                H_x     = false(2, nTestStates); 
                if fit_dist == 1
                    %// Parametric Estimation: Slower, but more robust; 
                    pd = fitdist(shuff_stat(x,:)', 'Half Normal'); % half-normal because errors are distance scalars
                    %ci = paramci(pd, 'alpha', bonFerrpVal); 
                    critVal(x) = pd.icdf(1-bonFerrpVal);
                else
                   %// Directly convert to emprical cdf; 
                   [vals, idx] = ecdf(shuff_stat(x,:)); 
                   ix = find(vals > 1-bonFerrpVal, 1); 
                   critVal(x) = idx(ix); 
                end
            % 
                if unit_stat > critVal
                    H_x(1,x) = 1; 
                end
                if bkgd_stat > critVal
                    H_x(2,x) = 1; 
                end
            end
            H_Unit.(test) = H_x(1,:); 
            H_Bkgd.(test) = H_x(2,:); 
        end


        %% 'Tacked On' (abnormal) Elementwise Shuffles; 
        %// Done post-hoc here to avoid huge memory costs; 
        %________________________
        sss = sdoStruct(m).shuffles{u}; 
        dUnit  = sdoStruct(m).sdos{u}; 
        dBkgd  = sdoStruct(m).bkgrndSDO; 
        jUnit  = sdoStruct(m).sdosJoint{u};
        jBkgd  = sdoStruct(m).bkgrndJointSDO; 
        if ~isempty(sss.SDOJointShuff)
            % We have shuffles; 
            dShuff = sss.SDOShuff; 
            jShuff = sss.SDOJointShuff; 
        else
            %__ simulate; 
            % WARNING: These may inaccurately capture the original variance
            % at the tails. 
            N_SHUFF = 1000; 
            dShuff = SAT.sdoUtils.generateShuffleMatrices(...
                sss.SDOShuff_mean, sss.SDOShuff_std, N_SHUFF, 'conform', 'L'); 
            jShuff = SAT.sdoUtils.generateShuffleMatrices(...
                sss.SDOJointShuff_mean, sss.SDOJointShuff_std, N_SHUFF, 'conform', 'M'); 
        end
        rdShuff = SAT.sdoUtils.reparameterizeSdo(dShuff,jShuff,jUnit);
        rdBkgd  = SAT.sdoUtils.reparameterizeSdo(dBkgd, jBkgd, jUnit); 
       

        meanShuff = mean(rdShuff,3); 
        se_pxx_Shuff_MeanShuff = (rdShuff-meanShuff).^2; 
        se_pxx_Unit_MeanShuff  = (dUnit-meanShuff).^2; 
        se_pxx_Bkgd_MeanShuff   = (rdBkgd-meanShuff).^2; 


        nStates = size(rdShuff,1); 

        H_mat = zeros(nStates,nStates,2); 
        bonFerrpVal = SIG_PVAL/nStates.^2; 

        for row = 1:nStates
            for col = 1:nStates
                if fit_dist == 1
                    pd = fitdist(squeeze(se_pxx_Shuff_MeanShuff(row,col,:)), 'Half Normal'); 
                    critVal = pd.icdf(1-bonFerrpVal); 
                else
                   [vals, idx] = ecdf(squeeze(se_pxx_Shuff_MeanShuff(row,col,:))); 
                   ix = find(vals > 1-bonFerrpVal, 1); 
                   critVal(x) = idx(ix);     
                end
                if se_pxx_Unit_MeanShuff(row,col) > critVal
                    H_mat(row,col,1) = 1; 
                end
                if se_pxx_Bkgd_MeanShuff(row,col) > critVal
                    H_mat(row,col,2) = 1; 
                end

            end
        end
        H_Unit.se_pxx_px0Norm = H_mat(:,:,1); 
        H_Bkgd.se_pxx_px0Norm = H_mat(:,:,2);


        sdoStruct(m).stats{u}.isSig_Unit = H_Unit; 
        sdoStruct(m).stats{u}.isSig_Bkgd = H_Bkgd; 


        % __ >> Here, we test if Shuff - Test is not normal around 0
        


        %________________________



        %{
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
        
        %... TODO fill in as many tests as desired: We need to be sure to prepopulate the statsSig elements.  
        %}
    end
end

end

%CUT: 
% __ Alternative stat test; normal
                %{
                pd = fitdist(squeeze(rdShuff(row,col,:)), 'Normal'); 
                critVals = pd.icdf([bonFerrpVal, 1-bonFerrpVal]); % i.e. two-tailed. 
                if (dUnit(row,col) > critVals(2)) || (dUnit(row,col) < critVals(1))
                    H_mat(row,col,1) = 1; 
                end
                if (rdBkgd(row,col) > critVals(2)) || (rdBkgd(row,col) < critVals(1))
                    H_mat(row,col,2) = 1; 
                end
                %}