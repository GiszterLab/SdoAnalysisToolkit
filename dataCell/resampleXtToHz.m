%% Resample X(t) to Specified Hz
% Macro to handle resampling time series data from sampling frequency 'FS' to
% desired frequency 'newFS'
%
% CONFORM = ensure xt max and xt min are preserved by resampling; clipping
% if necessary; 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

% 8.25.2022: Partial upgrade to permit arrays to be passed/processed at
% once; 

function [rsXt] = resampleXtToHz(Xt, FS, newFS, CONFORM)
if ~exist('CONFORM', 'var')
    CONFORM = 0; 
end

% if an MxN Array, will perform columnwise; 

%// a bit more robust way of doing this; 

    decF = FS/newFS; 

    if ismembertol(decF,1)
        %// No change
        rsXt = Xt; 
    elseif ismembertol(decF, round(decF))
        %// decF is effectively an int; --> Normal Downsample
        if ~any(size(Xt) == 1) 
            %// array; 
            rsXt0 = decimate(Xt(:,1), round(decF)); 
            rsXt = zeros(length(rsXt0), size(Xt,2)); 
            for col = 1:size(rsXt,2)
                rsXt(:,col) = decimate(Xt(:,col), round(decF)); 
            end
        else
            %// single time series
            rsXt = decimate(Xt, round(decF));
        end
    elseif ismembertol(1/decF, round(1/decF))
        %// decF is rational --> Normal upsample
        if ~any(size(Xt) == 1)
            %// array; 
            rsXt0 = interp(Xt(:,1), round(1/decF));
            rsXt = zeros(length(rsXt0), size(Xt,2)); 
            for col = 1:size(rsXt,2)
                rsXt(:,col) = interp(Xt(:,col), round(1/decF)); 
            end
        else 
            rsXt = interp(Xt, round(1/decF));
        end
    else
        %// Non integer upsample/downsample. Two stages; 
        LC = lcm(FS, newFS); % least-common multiple of two Hz
        % 1) Upsample 
        upXt = interp(Xt, round(LC/FS)); 
        %upXt = interpolate(Xt, round(LC/FS)); 
        % 2) Downsample
        rsXt = decimate(upXt, round(LC/newFS));
    end

if CONFORM
    minX = min(Xt); 
    maxX = max(Xt); 
    %
    LI_MAX = rsXt > maxX; 
    rsXt(LI_MAX) = maxX; 
    LI_MIN = rsXt < minX; 
    rsXt(LI_MIN) = minX; 
end
    
    
end