%% callAfilter (V2)
% A list of generic filtering methods to smooth timeseries data. Contains
% filters which operate in either the time or frequency domain. Some of
% these are redundant w/ the standard DSP toolbox, but are included for a
% commonality of utility
%
% Upgrade to ffxt from filtfilt to reduce ringing artifacts from short
% timeseries datasets when filtering in frequency
%
% INPUTS: 
%   'signal' - A timeseries data signal to filter; [1xN Array]
%   'type'- The filter type to use. Filters may be in time domain or
%       frequency domain. 
%       -- 'mov'
%           - (Time Domain) Moving average filter
%       -- 'gaussmov',
%           - (Time Domain) Moving average filter w/ gaussian kernel
%       -- 'trimov'
%           - (Time Domain) Moving average filter w/ triangular kernel
%       -- 'expmov',
%           - (Time Domain) Moving average filter w/ exponentially weighed kernel
%       -- 'rmsmov'
%           - (Time Domain) Root-mean-square calculated within a defined window. 
%       -- 'hamming' 
%           - (Time Domain) Hamming Window of nPoints. If auxVar == 1; rectify 
%       -- 'hanning' 
%           - (Time Domain) Hanning Window of nPoints. If auxVar == 1; rectify 
%       -- 'blackman'
%           - (Time Domain) Blackman Window of nPoints. If auxVar == 1; rectify 
%       -- 'bandpass'
%           - (Frequency Domain) Pass-band filter with endpoint artifact attenuation
%       -- 'butter',
%           - (Frequency Domain) (High pass????) filter
%       -- 'emgbutter'
%           - (Frequency Domain) 10 Hz HiPass + X Hz Lowpass
%       -- 'notch'
%           - (Frequency Domain) 60 Hz Line noise notch filtering,
%           harmonics 1-8
%       -- 'notchRMS'
%           - (Hybrid) 60Hz Notch filter + RMS moving average. 
%           - Useful for raw EMG. 
%   POSITIONAL ARGUMENTS
%       [WindowBin/FilterHz]
%           - INTEGER or [INTEGER, INTEGER]; 
%           - If using time-domain filter, this is the length of the 
%           filtering window. 
%           - If using a frequency domain filter, this is the filterband. 
%       [Support Var]
%           - Optional secondary argument for the respective filter type.
%           - if 'gaussmov'; standard deviation of gaussian. 
%           - if 'expmov',' time constant for exponential kernel
%           - if 'notch' or 'notchRMS', is the notch filter freq. 
%   NAME-VALUE PAIRS
%       'fs' - Signal frequency. Required if using a frequency filter. 

% Adapted from Maryam A.B.'s original filter definitions, then expanded and
% generalized. 

% TODO: allow causal vs. acausal variants of filters
% TODO: Breakup highpass,lowpass,bandstop

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

%% Maryam's filtersets
%function [fSignal, filterparams]=callAfilter(tinterval,signal,type,argvarin)
function [fSignal]=callAfilter(signal,type,varargin)

p = inputParser; 
addOptional(p, 'nPoints', 25);  
addOptional(p, 'auxVar', 1); 
addParameter(p, 'fs', 1000); 
parse(p, varargin{:}); 
pR = p.Results; 
%____

%// Pass to either time-domain of frequency-domain filters; 
N_POINTS    = pR.nPoints; 
FILT_HZ     = pR.nPoints;
SIG_HZ      = pR.fs; 

%// Filter-dependent secondary support var; defaulted to 1; 
SUPPORT_VAR = pR.auxVar; 

NOTCH_HZ = 60; 
switch type
    case {'notch', 'notchRMS'}
        if SUPPORT_VAR > 1
            NOTCH_HZ = SUPPORT_VAR; 
        end
end
    %case {'mov', 'gaussmov', 'trimov', 'expmov', 'rmsmov'


[sz_y, sz_x] = size(signal); 
TRANSPOSE = 0; 
%// we use a row-vector notation for our input to this function, but MATLAB
%by default uses column-vector notation; transpose as necessary
if sz_y > 1 && sz_x < 2
    TRANSPOSE = 1; 
    signal = signal'; 
end

switch type
    
    %% Time-based Filters
    case 'mov'
        b = 1/N_POINTS*ones(1,N_POINTS);
        fSignal = ffxt(b,1,signal); 
        
    case 'gaussmov' 
        %// gaussian-weighted moving-average
        sig = SUPPORT_VAR; 
        b = getgausskernel(N_POINTS/2, sig); 
        fSignal = ffxt(b, 1, signal); 
        
    case 'trimov'
        %// Triangular-Weighted Moving Average
        b0 = 1/N_POINTS:1/N_POINTS:1; 
        b = b0/sum(b0); 
        fSignal = ffxt(b,1, signal);
        
    case 'expmov'
        %// Exponentially-Weighted Moving Average
        if nargout > 1
            tau = SUPPORT_VAR;  
        else
            tau = N_POINTS/10; 
        end
        b0       = exp(tau*1/N_POINTS:1/N_POINTS:1); 
        b = b0/sum(b0); 
        fSignal = ffxt(b,1,signal);
        
    case {'rmsmov', 'rms', 'RMS', 'RMSmov', 'movRMS'}
        %// Root-mean Squared Filtering
        signal = abs(signal); 
        sig2 = signal.^2; 
        mov = SUPPORT_VAR; 
        b = 1/mov*ones(1,mov); 
        fsig2 = filtfilt(b,1,sig2); 
        fSignal = sqrt(fsig2); 

    case 'hamming'
        %// Hamming-Type window; Requires the DSP toolbox
        if SUPPORT_VAR == 1
            signal = abs(signal); 
        end
        b = hamming(N_POINTS); 
        filtfilt(b,1,signal)

    case 'hanning'
        %// Hanning-Type window; Requires the DSP toolbox
        if SUPPORT_VAR == 1
            signal = abs(signal); 
        end
        b = hann(N_POINTS); 
        filtfilt(b,1,signal); 

    case 'blackman'
        %// Blackman type window; Requires the DSP toolbox
        if SUPPORT_VAR == 1
            signal = abs(signal); 
        end
        b = blackman(N_POINTS); 
        filtfilt(b,1,signal); 

        
    %% Frequency-based Filters
    case {'bandpass', 'bp'} 
       %// Book-ended variant of Bandpass filter to avoid artifacting
       %endpoints
       signal_bkend = [fliplr(signal(1:SIG_HZ)) signal fliplr(signal(end-SIG_HZ+1:end))];
       %bp0 = argvarin{1}(1); %Lower bound
       %bp1 = argvarin{2}(2); %Upper bound
      
       fSig = bandpass(signal_bkend, FILT_HZ, SIG_HZ); 
       
       %fSig = bandpass(signal_bkend, argvarin, SIG_HZ); 
       fSignal = fSig(SIG_HZ+1:end-SIG_HZ);
        
   case 'butter'
       %// Generic butterwoth
       
       cutHz = FILT_HZ; 
       %cutHz=argvarin(:);
       Wn=cutHz/SIG_HZ*2;
       [B,A]=butter(4,Wn);
       fSignal=filtfilt(B,A,signal);

    %{
    case 'nonlinear'
        [B,A] = butter(4,10/SIG_HZ*2,'high');
        signalH=filtfilt(B,A,signal);
        absSignalH=abs(signalH);
        max_emg=max(absSignalH);
        max_out_ratio = 0.7;
        [fSignal, filterparams] = emg_filter_test(absSignalH,max_emg,max_out_ratio);
    %}
        
    case 'emgButter'            
        [B,A] = butter(4,10/SIG_HZ*2,'high');
        signalH=ffxt(B,A,signal);
        cutHz = FILT_HZ; 
        Wn=cutHz/SIG_HZ*2;
        [BL,AL] = butter(4,Wn,'low');
        fSignal=filtfilt(BL,AL,abs(signalH));

    case 'notch'
        %// First 8 harmonics
        for i=1:8
            wo = i* NOTCH_HZ/(SIG_HZ/2);  
            bw = NOTCH_HZ/SIG_HZ*2/35;
            [b,a] = iirnotch(wo,bw);          
            signal = filtfilt(b,a,signal); 
        end
        fSignal = signal; 
      
    %% Hybrid Filters
        
    %{
    case 'notchNonlinear'         
        for i=1:8 %for each harmonic
            wo = i* 60/(SIG_HZ/2);  bw = 60/SIG_HZ*2/35;
            [b,a] = iirnotch(wo,bw);
            signal=filtfilt(b,a,signal);
        end
        [B,A] = butter(4,10/SIG_HZ*2,'high');
        signalH=filtfilt(B,A,signal);
        absSignalH=abs(signalH);
        max_emg=max(absSignalH);
        max_out_ratio = 0.7;
        [fSignal, filterparams] = emg_filter_test(absSignalH,max_emg,max_out_ratio);
    %}
        
    case {'notchRMS', 'notchrms'}
        for i=1:8 %for each harmonic
            wo = i* NOTCH_HZ/(SIG_HZ/2);  
            bw = NOTCH_HZ/SIG_HZ*2/35;
            [b,a] = iirnotch(wo,bw);
            signal = ffxt(b,a,signal); 
        end
        %mov=argvarin(:);
        % -- Bookend signal to prevent endpoint filter artifacts
        %signal_bkend = [fliplr(signal(1:mov)) signal fliplr(signal(end-mov+1:end))]; 
        %signal_bkend = [mean(signal(1:mov))*ones(1,mov) signal mean(signal(end-mov+1:end))*ones(1,mov)]; 
        [B,A] = butter(4,10/SIG_HZ*2,'high');
        [b2] = 1/N_POINTS*ones(1,N_POINTS); 
        %signalH=filtfilt(B,A,signal_bkend);
        %fSignal_bkend=sqrt(filtfilt(1/mov*ones(1,mov),1,signalH.^2));
        signalH = ffxt(B,A,signal); 
        fSignal = sqrt(ffxt(b2,1,signalH.^2)); 
        1; 
end

if TRANSPOSE
    fSignal = fSignal'; 
end

end

%// CUT
%// if the type is butter argvarin is cutoff
%// if type is moving average then argvarin is the order of it
%{
if length(tinterval) >1 
    stepSec=tinterval(2)-tinterval(1);
else
    stepSec = tinterval; 
end
%}
% __ We could term the SIG_HZ later in the equation, as necessary; 

%{
nargs = length(varargin); 
argType = class(varargin); %// see if we're passing doubles, arrays, or cells 

supVar_1 = 1; 
supVar_2 = []; 

%// Parse Vars by FType
switch type
    case {'mov', 'gaussmov', 'trimov', 'expmov', 'rmsmov'}
        %// Time-Domain Filtering
        % First val = Points;
        % Second val = Auxillary/Support var
        switch argType
            case {'double'}
                N_POINTS = varargin(1); 
                if nargs > 1
                    supVar_1 = varargin(2); 
                end
            case {'cell'}
                N_POINTS = varargin{1}; 
                if nargs > 1
                    supVar_1 = varargin{2}; 
                end
        end
        
    case {'bandpass', 'bp', 'butter', 'nonlinear', 'notch'}
        %// Frequency-Domain Filtering
        
        %// find filtering frequency
        
        switch argType
            case {'double'}
                SIG_HZ = varargin(1); 
                %ffs = argvarin(1); 
                if nargs > 1
                    %supVar_1 = argvarin(2); 
                    ffs = varargin(2); 
                end
            case {'cell'}
                %// may be necessary for passing a band
                %ffs = argvarin{1}; 
                SIG_HZ = varargin(1); 
                if nargs > 1
                    %supVar_1 = argvarin{2};
                    ffs = varargin{2}; 
                end
        end
        
    case {'notchRMS', 'notchrms'}
        %// Hybrid Filters
        switch argType
            case {'double'}
                SIG_HZ = varargin(1); 
                if nargs > 1
                    N_POINTS = varargin(2); 
                end
            case {'cell'}
                SIG_HZ = varargin{1}; 
                if nargs > 1
                    N_POINTS = varargin{2}; 
                end
        end
        
end


SIG_HZ=1/stepSec;
fSignal=[];
filterparams=[];

%}
%steps=diff(tinterval)%check for even steps
%if all(diff(steps)<=0.1*steps(1))\