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

% 1.24.2024 - Added a catch for cases where diagonal magnitude > 1

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
    
    nPages = size(sdoMat,3); 

    L_arr = zeros(size(sdoMat)); 


    for z = 1:nPages

    sMat = sdoMat(:,:,z); 
    L = sdoMat(:,:,z); 

   
    if SAT.sdoUtils.islinearsdo(L) 
        return
    end

    sdoColMag = sum(abs(sMat),1); 

    %% Offset negatives on off-diagonal
    % --> Scale positive components by negative magnitudes
    %// Logical index, Off-diagnal = negative
    LI_ODNeg = (sMat < 0); 
    LI_ODNeg(LIE) = 0; 

    mag_ODNeg = sum(abs(sMat).*LI_ODNeg,1); 

    scRow = sdoColMag./(sdoColMag-mag_ODNeg); 
    scRow(isnan(scRow)) = 1; 
    scMat = ones(N_STATES,1) * scRow; 

    L = L.*scMat; %Scale L; 
    L = L.*~LI_ODNeg; %set negative off-diagonal components to 0

    %% Remove positive elements on main diagonal
    %// if pos elements on main diag, scale positive off-diagonal elements
    %by offset of main diag; set diag to 0; 
    
    mainDiag        = diag(sMat)'; 
    LI_ODPos        = ~LI_ODNeg; 
    LI_ODPos(LIE)   = 0; 
    
    LI_MD       = (mainDiag>0); 
    
    %// either 1 or scalar multiplier; 
    scRow2      = sdoColMag./(sdoColMag-(mainDiag.*LI_MD)); 
    scMat2      = ones(N_STATES,1)*scRow2; 
    scMat2(isnan(scMat2)) = 1; 
 
    scMat2(isinf(scMat2)) = 1; 

    newDiag = min(0, mainDiag); 

    L = L.*(scMat2.*LI_ODPos); 
    
    L(LIE) = newDiag; 

    %% Sync back Columns to zero; 
    % --> If mag positive, counter balance by adding negatives to diag
    L2Diag = diag(L); 

    LColSum = sum(L); 

    LColSumPos = max(0, LColSum);

    L(LIE) = L2Diag - LColSumPos'; 

    % Posthoc (temp patch)
    L = normpdfcol2zero(L); 

    %% Scale sdo magnitude to original 

    LColMag = sum(abs(L),1); 

    dMag = sdoColMag./LColMag; 
    dMag(isnan(dMag)) = 1; 
    dMag(isinf(dMag)) = 0; 

    L = L*diag(dMag); 
    %dMagArr = ones(N_STATES,1)*dMag; 

    %L = L.*dMagArr; 

    %% Ensure no element in column has greater than 1 mag

    % take the larger of 1 or magnitude; find reciprocal; multiply; 
    invColMag = 1./max(max(abs(L),1), [], 1);  
    L = L*diag(invColMag); 
    %
    L_arr(:,:,z) = L; 
    end

    L = L_arr; 


end