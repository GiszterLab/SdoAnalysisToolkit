%% plotSDO_diffSDO
% Co-plot the background and spike-triggered SDO matrices from the 'sdo'
% datastructure as heatmaps
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

function plotSDO_plotDiffSDO(sdo,XT_CH_NO, PP_CH_NO, varargin)
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
SDOVariants = fieldNames(strcmp(fieldNames,'sdos') | strcmp(fieldNames,'bkgrndSDO'));
nSDOVariants=length(SDOVariants);
nCol=nSDOVariants + 1; % for subplots
h=figure('Position',[256   161   695   384 ]);
set(h,'Position',(h.Position).*[1 1 nCol 1])
subplot(1,nCol,1)

for i=1:nSDOVariants
    subplot(1,nCol,i)
    sdos=getfield(sdo,{XT_CH_NO},SDOVariants{i});
    if contains('cell',class(sdos))
        sdomatrix=sdos{PP_CH_NO};
    else
        sdomatrix=sdos;
    end
    if FILTER
        sdomatrix = SAT.sdoUtils.ffdiag([], 1, sdomatrix,1); 
    end
    imagesc(sdomatrix)
    colorbar
    if FILTER
        title(strcat(underscores2spaces(SDOVariants{i}), ' filtered')); 
    else
        title(underscores2spaces(SDOVariants{i})); 
    end
         
    line( [0, N_BINS], [0, N_BINS], 'color', [1, 1, 1], 'lineStyle', '--', 'lineWidth', 1.5); 
    axis square
    axis xy
    xlabel('x_0 State'); 
    ylabel('x_1 State'); 
    
end

subplot(1,nCol,nCol)

if ~isempty(sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff)
    L = mean(sdo(XT_CH_NO).shuffles{PP_CH_NO}.SDOShuff,3); 
    if FILTER
        L = SAT.sdoUtils.ffdiag([], 1, L); 
    end
else
    L = zeros(N_BINS); 
end

imagesc(L)
colorbar
if FILTER
    title(strcat('Mean ', sdo(XT_CH_NO).neuronNames{PP_CH_NO}, ' Shuff SDO (filtered)')); 
else
    title(strcat('Mean ', sdo(XT_CH_NO).neuronNames{PP_CH_NO}, ' Shuff SDO')); 
end
axis square 
axis xy
xlabel('x_0 State'); 
ylabel('x_1 State'); 

line( [0, N_BINS], [0, N_BINS], 'color', [1, 1, 1], 'lineStyle', '--', 'lineWidth', 1.5); 

suptitle2([ sdo(XT_CH_NO).neuronNames{PP_CH_NO} ' on ' sdo(XT_CH_NO).signalType])

if SAVE_FIG
    f = gcf; 
    plot_saveModule(f, SAVE_DIR, SAVE_FMT, "Diff_SDOs"); 
end

end