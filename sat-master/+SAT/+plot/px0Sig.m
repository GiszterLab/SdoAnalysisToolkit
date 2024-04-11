%% (Plot) px0Sig 
% Plot the distribution of states at time of spike relative to the
% distribution of states for the shuffles. For use within the SDO Analysis
% Toolkit.
%
% PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%   sdo: 'sdo' structure
%   XT_SDO_CH_NO: Row index for the sdo structure, pointing to a particular
%       xtDataChannel
%   PP_SDO_CH_NO: Subindex for the sdo structure, pointing to a particular
%       ppDataChannel
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Copyright (C) 2023  Trevor S. Smith
%  Drexel University College of Medicine
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

function px0Sig(sdoStruct, XT_CH_NO, PP_CH_NO, varargin)
p = inputParser; 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
%________

    SIG_PVAL    = sdoStruct(XT_CH_NO).stats{PP_CH_NO}.pVal; 
    N_BINS      = length(sdoStruct(XT_CH_NO).bkgrndSDO); 
   
    ppName0     = sdoStruct(XT_CH_NO).neuronNames{PP_CH_NO}; 
    ppName      = underscores2spaces(ppName0); 
    xtName      = sdoStruct(XT_CH_NO).signalType; 
    
    %// Will need to throw the resampler in here, if necessary; 
    sdoJointShuff = sdoStruct(XT_CH_NO).shuffles{PP_CH_NO}.SDOJointShuff;
    
    if isempty(sdoJointShuff)
        sdoJointShuff = zeros(N_BINS, N_BINS, 1); 
    end
    
    Z_LENGTH = size(sdoJointShuff,3); 
    if Z_LENGTH > 1
        px0_shuffle     = squeeze( sum(sdoJointShuff,1));  
    else
        %// transpose necessary because we are summing on dim2 below
        px0_shuffle     = sdoJointShuff'; 
    end
    px0_shuffleMean = mean(px0_shuffle,2)';
    px0_shuffleStd  = std(px0_shuffle,0,2)'; 
    
    sdoJoint = sdoStruct(XT_CH_NO).sdosJoint{PP_CH_NO};
    
    px0_unit = sum(sdoJoint,1); % current state probability associated with neuron spikes

    %___________

    figure; 
    
    subplot(1,2,1)
    
    hold on; 
    
    h1 = plot(1:N_BINS,px0_shuffle, 'color', [0.5, 0.5, 0.5, 0.2], 'DisplayName', ''); %[RGBA]; 
    %// plot mean
    h2 = plot(1:N_BINS,px0_shuffleMean, 'color', [0.2, 0.2, 0.2], 'lineWidth', 2); 
    %// plot +/- 1 STD; 
    h3 = plot([1:N_BINS, N_BINS:-1:1], [px0_shuffleMean+px0_shuffleStd, fliplr(px0_shuffleMean-px0_shuffleStd)], ...
        'color', [0.2, 0.2, 0.2], ...
        'lineWidth', 2, ...
        'lineStyle', ':'); 

    h4 = plot(1:length(px0_unit),px0_unit,'LineWidth',2,'color','r');
    ax = gca;
    set(ax,'XGrid','on')
    title({'p(x_0) [Unit] vs. p(x_0) [Shuffles] at spike'}); 
    xlabel('State (X)')
    ylabel('p(x_0|s)'); 
    leg = {'Shuffled', 'Shuffle Mean', 'Shuffle Mean \pm 1 STD', 'Observed'}; 
    legend([h1(1),h2,h3,h4], leg); 
   
%% 1D : current State

    subplot(1,2,2)
    %__
    KLcurr = squeeze(sdoStruct(XT_CH_NO).stats{PP_CH_NO}.comparisons.Shuff_v_MeanShuff.kld_px0_raw); 
    KLcurr_neuron = sdoStruct(XT_CH_NO).stats{PP_CH_NO}.comparisons.Unit_v_MeanShuff.kld_px0_raw; 
    %KLcurr = squeeze(sdo(XT_CH_NO).stats{PP_CH_NO}.KLcurr_shuff_meanshuff);
    %KLcurr_neuron = sdo(XT_CH_NO).stats{PP_CH_NO}.KLcurr_neuron_meanshuff;
    if any(KLcurr < 0)
        negI = (KLcurr<0); 
        KLcurr(negI)=abs(KLcurr(negI)); 
    end 
    %__
    if ~isempty(KLcurr)
        SAT.plot.getCommonCdfPlot(KLcurr,  KLcurr_neuron, SIG_PVAL)
    else
        SAT.plot.getCommonCdfPlot(0,0,0); 
    end

        xlabel('KL Deviation from baseline  1D dist.')
        ylabel('CDF(null dist. by shuffled spks)')
   %% SuperTitle
   
   suptitle2(strcat(ppName, " on ", xtName)); 
 
   %% Save Module; 

   if SAVE_FIG
       f = gcf; 
       plot_saveModule(f, SAVE_DIR, SAVE_FMT, 'px0Sig'); 
   end
   
end
