%% filterSpiketimeContinuous
% // A collection of methods to convert a set of impulses, input as a point
% process, into a continous function by convolving with a selected finite
% inpulse response (FIR) function 
%
% INPUTS: 
%   timestamps  = (1xN) array of event times (in Sec)
%   SIG_HZ      = Int. Sample frequency of output signal.  
%   T_MAX       = Doubles. Maximum time value to cast signal to. 
%   filterType = {'sg', '-hg', 'expd', 'tb'}. Which type of filter
%           - 'sg'  = Symmetrical Gaussian (0-mean on timestamp)
%           - '-hg' = Negative Half-Gaussian (anti-causal to timestamp)
%           - 'expd'= Exponential decay post-spike (causal)
%           - tb'   = Trailing Boxcar filter prior to spike (anticausal)
%   TAU         = Double. Time constant for impulse response, in sec. If
%       'gaussian', refers to STD. If exponential, lambda. If boxcar,
%       duration. 
% OPTIONAL NAME-VALUE PAIRS: 
%   'N_STD'     = Double. Number of standard deviations to estimate FIR
%       over (if gaussian), or iterations of TAU to estimate decay over (if
%       exponential decay)
%       - Default = 4; 

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

function [yt] = filterSpiketimeContinuous (timestamps, SIG_HZ, T_MAX, filterType, TAU, varargin)
p = inputParser(); 
addParameter(p, 'N_STD', 4); 
addParameter(p, 'SCALAR', 1); 
parse(p, varargin{:}); 
pR = p.Results; 

N_STD = pR.N_STD; 
SCALAR = pR.SCALAR; %basically unnecessary here

%% Prepare Discretely Sampled ConSig
xt_length = round(T_MAX * SIG_HZ); %number bins = num sec * num *bins/sec

xt = zeros(1, xt_length); 
st_conform = round(timestamps*SIG_HZ); %convert spiketimes into indexed impulse times
xt(st_conform) = 1; 

%% Build FIR

switch filterType
    %// ht = impulse response
    %// t0 = position of impulse relative to start of impulse response;
    case {'sg', 'sgs'} %; unsure of the difference between sgs and sg
        %% Symmetrical Gaussian (Acausal)
        ht = SCALAR*normpdf(-N_STD*TAU*SIG_HZ:N_STD*TAU*SIG_HZ, 0, TAU*SIG_HZ); 
        t0 = ceil(length(ht)/2); 
    case '-hg'
        %% Negative Half-Gaussian (Anticausal)
        ht = SCALAR*normpdf(-N_STD*TAU*SIG_HZ:0, 0, TAU*SIG_HZ); 
        ht = ht/sum(ht); %ensure integral sums to 1; 
        t0 = length(ht); 
    case 'expd'
        %% Exponential Decay (Causal)
        ht = SCALAR*exp(-1/(TAU*SIG_HZ) * (0:N_STD*TAU*SIG_HZ)); 
        ht = ht/sum(ht); %ensure integral sums to 1; 
        t0 = 1; 
    case 'tb'
        %% Trailing Box (Anticausal)
        ht = SCALAR/(SIG_HZ*TAU)*ones(1,SIG_HZ*TAU); 
        t0 = length(ht); 
        
end

%% Convolve

yt0 = conv(xt, ht); 
%// Trim back components from filt; 
yt = yt0(t0:end-(length(ht)-t0)); 

%{
%% OLD 
    case 'sgs' %// symmmetrical Gaussian summation
        %// E.g. sum spikes within a defined range, scaled according to
        %gaussian amplitude
        %1) Generate 1/0 array
        %2) Gaussian filter w/ mean amplitude == 1
        numStd = 4; 
        sig = TAU*SIG_HZ; % in bins
        % --
        log_array = zeros(size(signal)); %//logical array of bins (e.g. 0/1)
        log_array(round(timestamps*SIG_HZ)) = 1; 
        filt_sg = normpdf([-numStd*sig:numStd*sig], 0, sig); %generate gaussian waveform of designated size/ 
        filt_sg_std = filt_sg/max(filt_sg);             %scale mean amplitude to 1; 
%}    

end