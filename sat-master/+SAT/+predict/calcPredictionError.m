%% Calc Prediction Error
% For use within the SDO Analysis Toolkit.
% Generate the differences between the predicted t1 state and the observed
% t1 state for all cases of predictions shown. 
%
% Error rates are only running (error x position) or cumulative
% Summed running error == total error. 
% Terminal cumulative error = total error.
%
% L0 / E0 = Incidence of Error
% L1 / E1 = Magnitude of Error
% L2 / E2 = SSE of Error
% Linf    = Maximum magnitude of error 
%
% 'inStates' are the x0 (used for reordering); 
% 'outStates' all about predicted vals vs. observed vals
%
%TODO: Deal w/ empty x0StateArr

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

function errorArr = calcPredictionError(x0StateArr, x1StateArr, pdStateArr, x1PxArr, pdPxArr, N_BINS, varargin)
p = inputParser; 
addParameter(p, 'refName', ''); 
addParameter(p, 'nXtPts', 1); 
parse(p, varargin{:}); 
pR = p.Results; 

REFNAME = pR.refName;
N_XT_PTS = pR.nXtPts; %used to scale likelihoods; 

inType = class(pdStateArr); 
switch inType
    case 'cell'
        %MxN
        [N_XT_CH, N_PP_CH] = size(pdStateArr);         
    case 'struct'
        %1xN
        N_XT_CH = 1; 
        N_PP_CH = 1; 
        %// temporarily wrap; 
        pdStateArr  = {pdStateArr}; 
        x0StateArr  = {x0StateArr};
        x1StateArr  = {x1StateArr}; 
        pdPxArr     = {pdPxArr}; 
        x1PxArr     = {x1PxArr};
end               
%___
sfields     = fields(pdStateArr{1,1}); 
N_FIELDS    = length(sfields); 

if ~exist('N_BINS', 'var')
    N_BINS = max(x1StateArr{1,1}); 
end

errorArr = cell(N_XT_CH, N_PP_CH); 

for m = 1:N_XT_CH
    for u = 1:N_PP_CH
        errorS      = SAT.predict.errorStruct_new(N_FIELDS);
        x0States    = x0StateArr{m,u};
        x1States    = x1StateArr{m,u}; 
        x1Px        = x1PxArr{m,u};
        %__ Field-Wise Comp;
        for f = 1:N_FIELDS
            fName       = sfields{f};
            pdStates    = pdStateArr{m,u}.(fName); %data
            pdPx        = pdPxArr{m,u}.(fName);     %data; 
            errorS(f).fieldname     = fName; 
            errorS(f).reference     = REFNAME; 
            errorS(f).dof_px_correct = 0; 
            %+++_____________ Original Data ___________ ++++
            errorS(f).x0States      = x0States; 
            errorS(f).predicted_px  = pdPx; 
            %================= STATE PREDICTIONS ===================
            %|| L0 Error: (Mismatch, 1/0, Error)
            errorS(f).L0_running    = ~ismembertol(x1States-pdStates,0);
            %|| L1 Error: Distance
            errorS(f).L1_running    = abs(x1States-pdStates); 
            %|| L2 Error: Variance
            errorS(f).L2_running    = (x1States-pdStates).^2; 
            %|| L inf Error: Single Max Error; 
            errorS(f).L_inf         = max( abs(x1States-pdStates)); 
            %____ StateWise Error Rates (relative to REFERENCE/OBS States)
            errorS(f).L0_x_state            = zeros(1,N_BINS); 
            errorS(f).L0_running_x_state    = cell(1,N_BINS);
            errorS(f).L1_x_state            = zeros(1,N_BINS); 
            errorS(f).L1_running_x_state    = cell(1,N_BINS); 
            errorS(f).L2_x_state            = zeros(1,N_BINS); 
            errorS(f).L2_running_x_state    = cell(1,N_BINS); 
            for xx = 1:N_BINS %per X0 state
                %
                xObsIdx = (x0States == xx);
                if nnz(xObsIdx) < 1 
                    continue; 
                end
                % __ Run Comps; 
                errorS(f).L0_running_x_state{xx}        = ~ismembertol(x1States(xObsIdx)-pdStates(xObsIdx), 0); 
                errorS(f).L0_x_state(xx)                = sum(errorS(f).L0_running_x_state{xx});
                errorS(f).L1_running_x_state{xx}        = abs(x1States(xObsIdx)-pdStates(xObsIdx)); 
                errorS(f).L1_x_state(xx)                = sum(errorS(f).L1_running_x_state{xx}); 
                errorS(f).L2_running_x_state{xx}        = errorS(f).L1_running_x_state{xx}.^2; 
                errorS(f).L2_x_state(xx)                = sum(errorS(f).L2_running_x_state{xx}); 
                
            end
            %================= DISTRIBUTION PREDICTIONS =============
            %// KLD between predicted and observed distributions (P|Q)
            errorS(f).KLD   = pxTools.KLDiv(pdPx, x1Px,1); %MAB script
            %// Log-Likelihood (less meaningful, but present metric)
            errorS(f).logLikelihood = pxTools.getLikelihood(pdPx, x1Px, 'log', 'nPoints', N_XT_PTS); 
        end
        errorArr{m,u} = errorS; 
    end
end

switch inType
    case 'struct'
        errorArr = errorArr{1,1}; %unwrap to match input; 
end

end

