%% sdoAnalysis_demo (OOP)
%
% Demonstration of the SDO Analysis Toolkit; 
% Run an SDO analysis using the Object-Oriented Programming (OOP)
% class-method data wrappers. 
%

%_______________________________________
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
%__________________________________________


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
%
xtdc.dataField = 'raw'; 
xtdc.mapMethod = 'logsigned'; 
%xtdc.mapMethod = 'linearsigned'; 
xtdc.nBins      = 40; 
%
xtdc = xtdc.discretize(); %state-map signal

% __ Initialize and populate a 'ppDataCell', class


ppdc = ppDataCell(); 
ppdc.import(ppData); 
% // Shuffle Spiketimes 
ppdc.shuffle; 

% __ Generate pre-spike (px0) and post-spike (px1) 'pxt' classes; 
%// Prespike
px0 = pxtDataCell(); 
px0.duraMs = -10; 
%px0.duraMs = -10; % Negative here to refer to data -before- spiking event;
px0.import(xtdc, ppdc, XT_CH_NO, PP_CH_NO); 

%// PostSpike
px1 = pxtDataCell(); 
px1.duraMs = 20; 
px1.import(xtdc, ppdc, XT_CH_NO, PP_CH_NO); 

% __ compute the sdo from the 'sdoMat' class as the difference between probability distributions; 

smm = sdoMultiMat(); 


smm.compute(xtdc,ppdc); 


% __ Plot SDOs
%plot(sdo); 

smm.plot(XT_CH_NO,PP_CH_NO); 


% __ Internal Prediction Error; 
predictionError = smm.getPredictionError(xtdc, ppdc, XT_CH_NO, PP_CH_NO); 

plot(predictionError)

%{
% __ Make transition Matrices from the 'sdoMat' class
sdo.makeTransitionMatrices(xtdc, ppdc); 

% __ Predict a probability distribution from the 'sdoMat' class from an
% initial probability distribution; 
pd_px1 = sdo.getPredictionPxt(px0); 

% __ Compare predictions relative to observed post-spike probability
% distributions; 

pd_px1.comparePxt(px1); %compare against post-spike interval

% __ Plot prediction errors between the two 'pxt' classes; 
pd_px1.plotError; 
%}

clear ffile2 fdir1 ffile1 xtData0 ppData0