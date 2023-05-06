%% Error Struct DOF-PX Correct
%
% Function to perform an (Optional) Modification to the
% 'errorStruct' data structure containing the prediction errors from the 7HH
% for a given probability distribution relative to some observed value. 
%
% The H1 (T0=T1), H2 (Gauss Drift), and H3 (STA) effectively have a reduced
% number of parameters to optimize when generating a prediction :: p(x1)
% instead of p(x1|x0). Compensating for these differences may be useful for
% evaluating if SDO performance is --only because-- of the other parameters
% to optimize. 
%
% Simultanously, scaling down the errors of these HH by sqrt(N-1) [states]
% is not desirable either, as just because the SDO potentially can optimize
% by p(x1|x0) --> N^2, some of these states are never observed around
% spike transition and hence are never (potentially) used. Scaling errors
%  H1-H3 by 1/px compensates for this by scaling the magnitude of the
%  errors by the frequency of the data in the training set (pre-spike
%  state). 
%
% CORRECT = [1/0] : If 1, apply 1/px scaling. If 0, remove 1/px scaling,
% if applicable. Or maybe.... sqrt(N-1)?

% Trevor S. Smith, 2023
% Drexel University College of Medicine

% --> We still don't have a good scaling ratio yet... 


function [errorStruct] = dofPxCorrectError(errorStruct, CORRECT, METHOD)
if ~exist('CORRECT', 'var')
    CORRECT = 1; 
end
if ~exist('METHOD', 'var')
    SCF_TYPE = 'popDOF'; 
else
    SCF_TYPE = METHOD; 
end

hhNames = {'t0t1', 'gauss', 'STA'}; 

N_HH = length(hhNames); 

fNames = {errorStruct(:).fieldname}; 
N_STATES = length(errorStruct(1).L0_running_x_state); 

px0 = histcounts(errorStruct(1).x0States, 1:N_STATES+1, 'Normalization', 'probability'); 

%SCF_TYPE = 'invpx'; 
SCF_TYPE = 'DOF'; 

nSpikes = length(errorStruct(end).x0States); 
switch SCF_TYPE
    case 'invpx'
        scf = px0(errorStruct(end).x0States); 
    case 'DOF'
        scf = 1./sqrt(N_STATES-1)*ones(1, nSpikes);
    case 'popDOF'
        nPopStates = length(unique(errorStruct(end).x0States)); 
        scf = 1./sqrt(nPopStates-1)*ones(1, nSpikes); 
end
%_______________

for hh = 1:N_HH
    % -- Find Row Index
    hhI = find(strcmp(hhNames{hh}, fNames)); 
    if (errorStruct(hhI).dof_px_correct == 0) && (CORRECT == 1)
        %// Apply Correction; 
        errorStruct(hhI) = scaleErrorsPx(scf, px0, errorStruct(hhI)); 
        errorStruct(hhI).dof_px_correct = 1; 

    elseif (errorStruct(hhI).dof_px_correct == 1) && (CORRECT == 0)
        %// Apply 'un'correction
        scf = 1./scf; 
        %scf = 1./px0(errorStruct(1).x0States); 
        errorStruct(hhI) = scaleErrorsPx(scf, px0, errorStruct(hhI)); 
        errorStruct(hhI).dof_px_correct = 0; 

    end
end

end

% __ Helper Function 
function [errorRow] = scaleErrorsPx(scf, px0, errorRow)

    eFields = fields(errorRow); 
    
    % __ Strip Out MetaData Fields; 
    eNotName = {'fieldname','reference', 'x0States', 'dof_px_correct', 'L_inf'}; 
    
    for ee = 1:length(eNotName)
        notLI = ~strcmp(eNotName(ee), eFields);
        eFields = eFields(notLI); 
    end
    
    N_EFIELDS = length(eFields); 
    N_STATES = length(px0); 

    %____________
    %|| Scale doubles by x0=1/px; Scale Cells elementwise;
    
    for ee = 1:N_EFIELDS
        fClass = class(errorRow.(eFields{ee}));
        switch fClass
            case 'double'
                %// Scale errors by X0; 
                xLen = length(errorRow.(eFields{ee}));
                if xLen > N_STATES
                    errorRow.(eFields{ee}) = scf.*errorRow.(eFields{ee}); 
                else
                    errorRow.(eFields{ee}) = errorRow.(eFields{ee}).*px0; 
                end

            case 'cell'
                %// Scale errors by elementwise; 
                for xx = 1:N_STATES
                    errorRow.(eFields{ee}){xx} = errorRow.(eFields{ee}){xx}*scf(xx); 
                end
        end
    end

end
