%% conformsdo
%
% For a recovered stochastic dynamic operator to behave linearly for
% composition and prediction, (and to predict outside of the original bounds
% for whch it was created), it must not violate some underlying assumptions: 
%   0) The overall magnitude of sdo must not exceed 2
%   1) Each column must sum to 0
%   2) The SDO overall must sum to 0
%   3) The main diagonal must be non-positive
%   4) The Off-diagonal must be non-negative
%
% This script conforms the matrix to behave thusly. However, because of the
% necessary changes to the SDO, the immediate predictive behavior of the
% SDO may change accordingly. 
%
% ORDER OF OPERATIONS: 
%   1) Correct off-diagonal negative components; 
%       a) Positive elements in the SDO columns are scaled by the magnitude of
%       the erroneous negative components
%       b) Erroneous negative off-diagonal elements are set to 0. 
%   2) Correct main-diagonal positive components; 
%       a) Positive off-diagonal elements in the SDO colums are scaled by
%       the magnitude of the erroneous positive main-diagonal components; 
%       b) Erroneous postive main-diagonal elements are set to 0. 
%   3) Correct instances where SDO columns do not sum to 0. 
%       a) Postive sums are offset by an equivalent negative value to the
%       main diagonal. 
%       b) Negative sums ... have yet to be seen. 
%   4) Scale each column by original to ensure absolute magnitude of effect is
%   retained. 

% INPUT: 
%   sdoMat - differential SDO matrix
% OUTPUT: 
%   L - A linear operator from the SDO matrix, fully compliant with
%   assumptions of linearity and superposition. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine


function [L] = conformsdo(sdoMat)
    N_STATES = size(sdoMat,1); 
    LIE     = logical(eye(N_STATES)); %Logical eye index (for main diagonal)
   
    %% Check if SDO Matrix is a 'M'Type Arr; 
    %
    %// 5*10^-6 is aproximately tol
    if nnz(sdoMat<0) == 0 && sum(sum(sdoMat)) > 1/sqrt(N_STATES)
       % // If all positive values, and sums are reasonably large ...
       % probably a M type matrix
        %L = normpdfcol2unity(sdoMat); 
        L = sdoMat; 
        return
    end
    %} 
    %% First, we have to scale overall effects to theoretical max (2)
    %{
    allMagSum = sum(sum(abs(sdoMat))); 
    if allMagSum > 2 
        sclr = 2/allMagSum; 
        sdoMat = sdoMat * sclr; 
    end
    %}
    
    L = sdoMat; 
   
    if SAT.sdoUtils.islinearsdo(L) 
        return
    end

    sdoColMag = sum(abs(sdoMat),1); 

    %% Offset negatives on off-diagonal
    % --> Scale positive components by negative magnitudes
    %// Logical index, Off-diagnal = negative
    LI_ODNeg = (sdoMat < 0); 
    LI_ODNeg(LIE) = 0; 

    mag_ODNeg = sum(abs(sdoMat).*LI_ODNeg,1); 

    scRow = sdoColMag./(sdoColMag-mag_ODNeg); 
    scRow(isnan(scRow)) = 1; 
    scMat = ones(N_STATES,1) * scRow; 

    L = L.*scMat; %Scale L; 
    L = L.*~LI_ODNeg; %set negative off-diagonal components to 0

    %% Remove positive elements on main diagonal
    %// if pos elements on main diag, scale positive off-diagonal elements
    %by offset of main diag; set diag to 0; 
    
    mainDiag        = diag(sdoMat)'; 
    LI_ODPos        = ~LI_ODNeg; 
    LI_ODPos(LIE)   = 0; 
    
    LI_MD       = (mainDiag>0); 
    
    %// either 1 or scalar multiplier; 
    scRow2      = sdoColMag./(sdoColMag-(mainDiag.*LI_MD)); 
    scMat2      = ones(N_STATES,1)*scRow2; 
    scMat2(isnan(scMat2)) = 1; 

    scMat2(isnan(scMat2)) = 1; 

    newDiag = min(0, mainDiag); 

    L = L.*(scMat2.*LI_ODPos); 
    
    L(LIE) = newDiag; 

    %% Sync back Columns to zero; 
    % --> If mag positive, counter balance by adding negatives to diag
    L2Diag = diag(L); 

    LColSum = sum(L); 

    LColSumPos = max(0, LColSum);

    L(LIE) = L2Diag - LColSumPos'; 

    %% Finally, scale sdo magnitude to original 

    LColMag = sum(abs(L),1); 

    dMag = sdoColMag./LColMag; 
    dMag(isnan(dMag)) = 1; 
    dMag(isinf(dMag)) = 0; 

    dMagArr = ones(N_STATES,1)*dMag; 

    L = L.*dMagArr; 

end