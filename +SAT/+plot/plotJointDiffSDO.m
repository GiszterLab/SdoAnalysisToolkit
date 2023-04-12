%% plotSDO_jointDiffSDO
% Plot the joint and differential SDOs for the spike-triggered and
% background matrices
%
%PREREQUISITES:
%   computeSDO()
% INPUT PARAMETERS
%   sdo: 'sdo' structure
%   XT_SDO_CH_NO: Row index for the sdo structure, pointing to a particular
%       xtDataChannel
%   PP_SDO_CH_NO: Subindex for the sdo structure, pointing to a particular
%       ppDataChannel
%   OPTIONAL NAME-VALUE ARGUMENTS
%       'filter',        : [0/1]. If 1, use a diagonal gaussian smoothing filter. 
%       'saveFig'        : [0/1]. If 1, save plotted figure
%       'saveFormat'     : ['png'/'svg']. Save format for the figure; 
%       'outputDirectory': string/char. If not passed here, query user for
%           save position

% Maryam Abolfath-Beygi, 2018
% Trevor S. Smith, 2022

function plotSDO_plotJointDiffSDO(sdo,XT_CH_NO,PP_CH_NO, varargin)
p = inputParser; 
addParameter(p, 'filter', 1); 
addParameter(p, 'saveFig', 0); 
addParameter(p, 'saveFormat', 'png');
addParameter(p, 'outputDirectory', []); 
parse(p, varargin{:}); 
pR = p.Results; 

FILTER      = pR.filter;
SAVE_FIG    = pR.saveFig; 
SAVE_FMT    = pR.saveFormat; 
SAVE_DIR    = pR.outputDirectory; 
%________

N_BINS = size(sdo(XT_CH_NO).sdos{PP_CH_NO},1); 

fieldNames=fieldnames(sdo);
SDOVariants = fieldNames(contains(fieldNames,'sdo','IgnoreCase',1));
nSDOVariants=length(SDOVariants);
nCols=floor(nSDOVariants/2); % for subplots
h = figure; 
set(h,'Position',(h.Position).*[1 1 nCols 1]);
subplot(2,nCols,1)

for i=1:nSDOVariants
    subplot(2,nCols,i)
    sdos=getfield(sdo,{XT_CH_NO},SDOVariants{i});
    if contains('cell',class(sdos))
        sdomatrix=sdos{PP_CH_NO};
    else
        sdomatrix=sdos;
    end
    if FILTER
        sdomatrix = SAT.sdoUtils.ffdiag([], 1, sdomatrix,1); 
    end
    imagesc(sdomatrix),
    colorbar,
    if FILTER
        title(strcat(underscores2spaces(SDOVariants{i}), ' (filtered)'));
    else
        title(underscores2spaces(SDOVariants{i})); 
    end
    line( [0, N_BINS], [0, N_BINS], 'color', [1, 1, 1], 'lineStyle', '--', 'lineWidth', 1.5); 
    axis square
    axis xy
    xlabel('x_0 State'); 
    ylabel('x_1 State'); 
end

suptitle2([ sdo(XT_CH_NO).neuronNames{PP_CH_NO} ' on ' sdo(XT_CH_NO).signalType])

if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "JointDiff_SDOs"); 
end


end