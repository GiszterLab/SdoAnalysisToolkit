%% getDetrendedPerieventSignal
%
% Enhanced method for spike-triggered signal extraction w/ detrending.
% Useful for trying to isolate spike-triggered effects for conditional STA.
% 
% Designed for use with the dataCell classes. 

% This is based off the work of Poliakov, A. V., & Schieber, M. H. (1998).
% "Multiple fragment statistical analysis of post-spike effects in
% spike-triggered averages of rectified EMG." 
% Journal of neuroscience methods, 79(2), 143–150.
% https://doi.org/10.1016/s0165-0270(97)00172-6
% and
% Davidson, A. G., O'Dell, R., Chan, V., & Schieber, M. H. (2007). 
% "Comparing effects in spike-triggered averages of rectified
% EMG across different behaviors."
% Journal of neuroscience methods, 163(2), 283–294.
% https://doi.org/10.1016/j.jneumeth.2007.03.010

% Output signal is both detrended and mean-leveled. 

% TODO: Integrate this with the spike-triggered average matrix estimator to
% make a state-dependent tensor; 

function [dxtCell, Xs, at02] =getDetrendedPerieventSignal(xtdc, ppdc, USE_XT_CH, USE_PP_CH, vars); 
arguments
    xtdc
    ppdc
    USE_XT_CH       = 1:xtdc.nChannels; 
    USE_PP_CH       = 1:ppdc.nChannels; 
    %
    vars.method     = 'ISA'; %Increment-Segmented Average
    vars.dataField  = 'envelope'; %xtdc.dataField;
    vars.n_shift    = 0; 
    vars.z_delay    = 0; 
    vars.t0_nPoints = 20; % Pre spike baseline
    vars.t1_nPoints = 20; % Test duration
    vars.t2_nPoints = 20; % Post effect baseline
    vars.fs         = xtdc.fs; 
    vars.rectify    = 1; 
end


N_USE_XT = length(USE_XT_CH); 
N_USE_PP = length(USE_PP_CH); 

RECTIFY = vars.rectify; 

nt0 = vars.t0_nPoints; 
nt1 = vars.t1_nPoints; 
nt2 = vars.t2_nPoints; 

nt012 = nt0+nt1+nt2; 

%{
nPoints = 1000; 

%________ Baseline estimation

bsLineCell = cell(N_USE_XT,xtdc.nTrials); 
for m_i = 1:N_USE_XT
    m = USE_XT_CH(m_i);
    for tr = 1:xtdc.nTrials
        bsLineCell{m,tr} = xtdc.data{1,tr}(m).(vars.dataField)(1:nPoints); 
    end
end


%}
% This is a function of the size of the test durations; 
n_isa_points = max(nt0+nt1, nt1+nt2); 

nSampLen = vars.t0_nPoints+n_isa_points+vars.t1_nPoints+n_isa_points; 

% Extraction; 
%___________________________________________________

at01 = cell(N_USE_XT, N_USE_PP); 

for m_i = 1:N_USE_XT
    m = USE_XT_CH(m_i); 
    for p_i = 1:N_USE_PP
        p = USE_PP_CH(p_i); 
        [x0_vals, x1_vals] = dataCell.calculate.stateNearSpike(xtdc,ppdc, ... 
            m, p, 'dataField', vars.dataField, 'n_shift', vars.n_shift, ... 
            'z_delay', vars.z_delay, 't0_nPoints', n_isa_points+nt0, 't1_nPoints', nt1+nt2+n_isa_points, ...
            'fs', vars.fs); 
        if RECTIFY
            at01{m_i,p_i} = abs([x0_vals; x1_vals]); 
        else
            at01{m_i,p_i} = [x0_vals; x1_vals]; 
        end
    end
end


%______________________________
% 'ISA' Estimation' & Elimination
% --> Used to remove any systematic nonlinear/linear baseline effects. 

[X,Y] = meshgrid([0:2*n_isa_points-1], [1:nt0+nt1+nt2]);
idxGrid = X+Y; 

x_len = 2*n_isa_points; 
y_len = nt012; 

idxV = idxGrid(:); 
nComps = length(idxV); 
scV = nSampLen*ones(nComps,1); %scalar weighting; for future considerations; 

x0 = (y_len*n_isa_points)+1;  %2401
x1 = y_len*(n_isa_points+1); %2460; 

at02    = cell(N_USE_XT, N_USE_PP); 
isaCell = cell(N_USE_XT,N_USE_PP); 
%xCell   = cell(N_USE_XT, N_USE_PP); 
%sta_wv  = cell(N_USE_XT,1); %regular
%ista_wv = cell(N_USE_XT,1); % 'ISA' STA (detrended); 
Xs      = cell(N_USE_XT,N_USE_PP); 
dxtCell = cell(N_USE_XT,N_USE_PP); 
%
mn_pk_wv = cell(N_USE_XT,N_USE_PP); 
%
for m_i = 1:N_USE_XT
    %sta_wv{m_i} = zeros(2*n_isa_points+nt012,N_USE_PP); 
    %ista_wv{m_i}= zeros(nt012, N_USE_PP); 
    for p_i = 1:N_USE_PP
        % --> Spike-wise correction; 
        nSpikes             = size(at01{m_i, p_i},2); 
        at02{m_i,p_i}       = zeros(nt012, nSpikes); 
        %xCell{m_i,p_i}      = zeros(1, nSpikes); 
        isaCell{m_i,p_i}    = zeros(nt012, nSpikes); 
        mn_pk_wv{m_i,p_i}   = zeros(nSpikes,1); 
        %
        allSpkIdx0 = repmat(idxV, 1, nSpikes); 
        allSpkIdx = allSpkIdx0 + scV*(0:nSpikes-1); %indices of all positional lookup
        spkVal = at01{m_i,p_i}(allSpkIdx); %linear indices; 
        spkG = reshape(spkVal, x_len, y_len,nSpikes); 
        %___
        isaCell{m_i,p_i} = squeeze(mean(spkG,1)); %ISA is the average of the segmental averages
        at02{m_i,p_i}   = spkVal(x0:x1,:); %grab 'actual' spike region;
        Xs{m_i,p_i}     = spkVal(x0+nt0,:); % Signal AT spike X(s)
        %__ Average amplitude within Intervals; per-spike ____
        %{
        preSpikeEffect = mean(at02{m_i,p_i}(1:nt0,:)); 
        periSpikeEffect= mean(at02{m_i,p_i}(nt0+1:nt0+nt1,:)); 
        posSpikeEffect = mean(at02{m_i,p_i}(nt0+nt1+1:nt012,:));
        
        %____
        xCell{m_i,p_i} = periSpikeEffect-(preSpikeEffect+posSpikeEffect)/2; 
        mn_pk_wv{m_i,p_i} =periSpikeEffect; 
        %}
        dxtCell{m_i,p_i} = at02{m_i,p_i}-isaCell{m_i,p_i}; % ISA-subtracted spike-effects; 
        %{
        sta_wv{m_i}(:,p_i) = mean(at01{m_i,p_i},2); 
        ista_wv{m_i}(:,p_i)= mean(at02{m_i,p_i}-isaCell{m_i,p_i},2); %ISA-subtracted spike- effects; 
        %}
    end
end

if nargout == 1
    Xs = []; 
    at02 = []; 
elseif nargout == 2
    at02 = []; 
end



end