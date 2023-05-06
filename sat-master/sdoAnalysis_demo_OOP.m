%% sdoAnalysis_demo (OOP)
%
% Demonstration of the SDO Analysis Toolkit; 
% Run an SDO analysis using the Object-Oriented Programming (OOP)
% class-method data wrappers. 
%

% Trevor S. Smith, 2023
% Drexel University College of Medicine

if ~exist('xtData', 'var') || ~exist('ppData', 'var')
    [fpath_xt, fdir1] = uigetfile('*.mat', 'Open example xtData'); 
    [fpath_pp, fdir2] = uigetfile('*.mat', 'Open example ppData'); 

    ffile1 = fullfile(fdir1, fpath_xt); 
    ffile2 = fullfile(fdir2, fpath_pp); 

    xtData0 = load(ffile1); 
    ppData0 = load(ffile2); 
    xtfield = fields(xtData0); 
    ppfield = fields(ppData0); 
    xtData = xtData0.(xtfield{1}); 
    ppData = ppData0.(ppfield{1}); 
end

% __ Example SMU x EMG
XT_CH_NO = 8; 
PP_CH_NO = 12; 
% __ Example IN x EMG
%XT_CH_NO = 6; 
%PP_CH_NO = 4; 

% __ Initialize and populate an 'xtDataCell' class

xtdc = xtDataCell(); 
xtdc.import(xtData); 
xtdc = xtdc.discretize(); %state-map signal

% __ Initialize and populate a 'ppDataCell', class

ppdc = ppDataCell(); 
ppdc.import(ppData); 
% // Shuffle Spiketimes 
ppdc.shuffle; 

% __ Generate pre-spike (px0) and post-spike (px1) 'pxt' classes; 
%// Prespike
px0 = pxtDataCell(); 
px0.duraMs = -10; % Negative here to refer to data -before- spiking event;
px0.import(xtdc, ppdc, XT_CH_NO, PP_CH_NO); 
%// PostSpike
px1 = pxtDataCell(); 
px1.import(xtdc, ppdc, XT_CH_NO, PP_CH_NO); 

% __ compute the sdo from the 'sdoMat' class as the difference between probability distributions; 
sdo = sdoMat(); 
%// Optional (Slower) replacement of the estimated background w/ the
%background SDO generated w/ the same algorithim.
%sdo.computeBackgroundSdo(xtdc);

sdo.computeSdo(px0, px1); 
sdo.performStats; 

% __ Plot SDOs
plot(sdo); 

% __ Make transition Matrices from the 'sdoMat' class
sdo.makeTransitionMatrices(); 

% __ Predict a probability distribution from the 'sdoMat' class from an
% initial probability distribution; 
pd_px1 = sdo.getPredictionPxt(px0); 

% __ Compare predictions relative to observed post-spike probability
% distributions; 

pd_px1.comparePxt(px1); %compare against post-spike interval

% __ Plot prediction errors between the two 'pxt' classes; 
pd_px1.plotError; 

clear ffile2 fdir1 ffile1 xtData0 ppData0