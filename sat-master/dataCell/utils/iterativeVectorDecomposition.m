%% iterativeVectorDecomposition (IVD)
%
%// Takes a multidimensional signal, determines 'heading vectors'
%across these dimensions, extracting these vector pulses from the time
%series data, to build 'pulses' of excursion within a vector heading. Meant
%as a master script for swapping between different methods.
%
% Alternatively, can use ICA to determine independent vector components,
% and extract all activations ('pulses') simultaneously 
% INPUTS: 
%   - Xt        : timeseries data array; each row is an independent
%       dimension
%   - vExtract  : ['ica'/'pca'/'max'/'supplied'] ; vector extraction method
%           'ica' - independent components analysis (NOT supported yet)
%           'pca' - principal components analysis with singular value
%                 decomposition
%           'max' - peak-biased PCA
%           'supplied'; A weighting matrix is provided for vector
%               extraction
%   - W         : weighting matrix (optional) for each iterative component
%
% TODO: Incorporate the ICA component

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

function [pulseArr, pulseVect] = iterativeVectorDecomposition(Xt, vExtract, W)
    if ~exist('vExtract', 'var')
        vExtract = 'max'; 
    end
    if ~exist('W', 'var')
        W = []; 
    else
        vExtract = 'supplied'; 
    end
    
    X0 = Xt; %save original;
        
    % -- Strip NaNs before 
    LI = isnan(X0); 
    %Xt(:,isnan(Xt(1,:))) = []; 
    Xt(:,isnan(Xt(1,:))) = 0; 
    
    %// Upgrades to permit hyperdimensional extraction; 
    
    [nDim, nCols]   = size(Xt); 
    FM              = sqrt(sum(Xt.^2));     %Vector Magnitude
    
    pulseArr        = zeros(nDim, nCols); 	%Force Pulses
    pulseVect       = zeros(nDim, nDim);    %vector headings   
    
    % || ________ Decomposition For-Loop_________
    
    %// note that using 'max' here is effectively PCA; iteratively
    %subtraction of primary orthogonal components --> 
   
    % --> We'll just use ingrained functions unless we want max-mag IFVD
    
    switch vExtract
        case {'ica', 'ICA'}
            % ...
            % --> Should pipe through our ICA script
            
            MAX_N_POINTS = 1e9; %// ten million; 
            %// Auto-decimate based on max val; 

            1; 

            [U_act, nXt, invWAS, W, A, S, A0, C] = ts_ica (Xt ); 

            pulseVect = invWAS; 
            pulseArr = U_act; 

            disp ("ICA not included yet!"); 

            return
        case {'pca', 'PCA'}
            [W, pcaXt] = pca(Xt'); 
            %// PC only gives slope; Need to compensate for
            %intercept/offset by leveling to 0. 
            pulseArr = (pcaXt - median(pcaXt, 1, 'omitnan'))'; 
            pulseVect = W'; 
            
            % --> We need to ensure that the weighting coefficients are the
            % proper sign here. 
            1; 
            
            return
    end
            
            
    for dd = 1:nDim
        switch vExtract
            case {'ica', 'ICA'}
                %// rather than iteratively extract components, merely take
                %the ICA of it
                
                XT0 = weights*Xt; 
                pulseArr(dd,:)  = XT0(dd,:); 
                pulseVect(dd,:) = weights(dd,:); 
                %
                
                continue; 

            case 'max'
                % -- Iteratively remove force components at max force mag
                % // for now, start w/ peaks as peak of pure vector ? ??? 
                [~, subidx] = max(FM); 
                % -- Scaled vector components...       
                Vt = Xt(:,subidx); %ratio of mag as x at max == > Vector heading; 
                Vt0 = Vt/FM(subidx);  %normalized vector heading of max-mag component
                
            case 'supplied'
                Vt = W(dd,:); 
                Vt0 = Vt; 
        end
                
        VM = sum(Vt.^2).^0.5;                   %Reference vector magnitude      
  
        try
            cosTheta = (Vt'*Xt)./(VM.*FM);      %cosine similarity [ A o B/ |A||B|]
        catch
            cosTheta = (Vt*Xt)./(VM.*FM); 
        end
        
        VPM = cosTheta.*FM;                     %projected component within the Defined Vector; 
        VDt = rowMult(VPM, Vt0);                %Vector heading scaled by in-plane magnitude;  
    
        D0 = Xt - VDt;                          %Remaining unaccounted-for-data         
    
        % __ Store; 
        pulseArr(dd,:)  = VPM; 
        pulseVect(dd,:) = Vt0; 
        % __ Reset for iteration;       
        Xt = D0; 
        FM = (sum(D0.^2)).^0.5; 
        clear xta yta zta xt0 yt0 zt0 Ft VPM VDt D0
        
    end
    
    % -- Weight Mat Arr to 1; 
   
    normArr = repmat(sqrt(sum(pulseVect.^2, 2)),1,length(pulseVect)); 
    pulseVect = pulseVect./normArr; 
    
    if strcmpi(vExtract, 'ica')
        %// sometimes ICA extracts negative weights + negative activations
        %--> if activations are primarily negative, flip sign of weights; 
        for d=1:nDim
            if sum(pulseArr(d,:)) < 1
                pulseArr(d,:) = -pulseArr(d,:); 
                pulseVect(d,:)= -pulseVect(d,:); 
            end
        end
    end
       
    
   % -- 
   %{
   if nnz(LI) > 0
        %// Compensate for NaNs; 
        V0 = nan*ones(size(X0)); 
        LI2 = ~any(LI,1); 
        V0(:,LI2) = 
        %V0(:,LI2) = pulseArr; 
        pulseArr = V0; 
   end
    %}

end 