%% pxTools_getH0Array
% Get null hypothesis matrix of defined dimensions and filtering. 
% If no filtering used, return the identity matrix
% 
% For this to be truly comparable to px1|x0, need to normalize mat to px0
% 
% Note that columns of terminal states cannot be normalized to 1 (otherwise
% the predicted time series is no longer stationary and breaks down... )
% --> norming to unity should ONLY occur for the final predicted transition
% matrix
%INPUTS: 
%   N_BINS        = order of matrix
%   PX_FSM_WID    = Number of states to calculate gaussian over
%   PX_FSM_STD    = Gaussian Sigma
% 
% OPTIONAL NAME-VALUE PAIRS: 
%   type: {'M'/ 'L'}; Whether to use transition mat or change of transition
%   mat. 
%     
%OUTPUTS: 
%   %h0Array    = [N_BINS x N_BINS] array containing the transition matrix.

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [h0Array] = pxTools_getH0Array(N_BINS, PX_FSM_WID, PX_FSM_STD, varargin)
defaultType = 'M'; 
expectType =  {'M', 'L', 'm', 'l',}; 
p = inputParser; 
addOptional(p, 'type', defaultType, ... 
    @(x) any(validatestring(x, expectType))); %['M'/'L']
parse(p, varargin{:}); 
pR = p.Results; 

arrType = pR.type; 

%// mimic effect of filter size on 
    if ~exist('PX_FSM_WID', 'var')
        PX_FSM_WID = 0; 
    end
    if ~exist('PX_FSM_STD', 'var')
        PX_FSM_STD = 0; 
    end

    h0Array = eye(N_BINS); 
    
    if PX_FSM_STD > 0 
        rollPdf = normpdf(-N_BINS+2:N_BINS, 1, PX_FSM_STD); 
        % --> Subsample and roll; 
        for bin = 1:N_BINS
            temp = circshift(rollPdf, bin-1);
            %h0Array(:,bin) = temp(N_BINS:end)/sum(temp(N_BINS:end));
            h0Array(:,bin) = temp(N_BINS:end); 
        end
    end
    
    switch arrType
        case {'M', 'm'}
            %// Markov/Transition Matrix; 
            %h0Array = normpdfcol2unity(h0Array);
            
            %// Switch for if we want to eventually normalize... 

        case {'L', 'l'}
            %// Differential Matrix
            matColSum = sum(h0Array); 
            LIE = logical(eye(N_BINS)); 
            h0Array(LIE) = h0Array(LIE) - matColSum';
    end
    %{
    fcoeff=exp(-(-PX_FSM_WID:PX_FSM_WID).^2/(2*PX_FSM_STD^2));
    fcoeff=fcoeff/sum(fcoeff);
    h0Array = filtfilt(fcoeff, 1, h0Array); 
    h0Norm = repmat(sum(h0Array,1), NBINS,1);
    %// col-norm
    h0Array = h0Array./h0Norm; 
    %}
end
    