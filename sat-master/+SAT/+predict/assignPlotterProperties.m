%% (predictSDO) assignPlotterProperties
%
% For use within the SDO Analysis Toolkit.
% Generates the 'plotProp' struct, a structure which contains information
% about -how- to plot different hypotheses on common plots. This allows the
% common plotters to be less strictly defined in -how- they generate plots
% intrinsically, but requires stronger typing here. 
%
% The line properties used here are under the assumption of the 7
% hypotheses in the order: {'t0t1', 'gaussH0', 'STA', 'mkv', 'bck', 'STA', 'SDO'};
% 
% If a different number of hypotheses are used, or these are reordered by
% the user, then the user should also change the number of elements defined
% here. 
%
% Currently up to 7 hypotheses may be used with customized plotting
% properties. Additional hypotheses will result in randomly generated
% colors. 
%
% INPUT: 
%   fieldNames: A {1xN} cell of strings matching the fieldNames in
%   errorArray and predicted_px. 
% OUTPUT: 
%   plotProp: A (1xN) structure containing 'color', 'LineStyle', and 
%   'LineWidth' elements, indexed by N. This may be optionally passed to
%   predictSDO plotters to maintain consistency across plots. 

% Trevor S. Smith, 2022
% Drexel University College of Medicine

function [plotProp] = assignPlotterProperties(fieldNames) 

N_FIELDS = length(fieldNames); 

% __> these need to be in the same order as the queried element... 
%{
plotProp = struct( ...
    'fieldname',    cell(1,N_FIELDS), ...
    'color',        cell(1,N_FIELDS), ...
    'lineStyle',    cell(1,N_FIELDS), ...
    'lineWidth',    cell(1,N_FIELDS) ...
    ); 
%}

N = 1; 

% -- [H1] T0T1
el_1 = fieldNames{1};              %// Thick and Red
plotProp.(el_1).color           = [230,000,000]/255; 
plotProp.(el_1).LineStyle       = '--'; 
plotProp.(el_1).LineWidth       = 2; 

N = N+1; 
if N > N_FIELDS; return; end

% -- [H2] Gaussian
el_2 = fieldNames{2};              %// Gold/yellow
plotProp.(el_2).color           = [179,179,000]/255;
plotProp.(el_2).LineStyle       = '-';
plotProp.(el_2).LineWidth       = 1.5; 

N = N+1; 
if N > N_FIELDS; return; end

% -- [H3] (simple) STA
el_3 = fieldNames{3};                %// Dashed- (dark)blue
plotProp.(el_3).color           = [0 0.4470 0.7410]; %cyan
%plotProp.(el_3).color           = [034,000,204]/255; 
plotProp.(el_3).LineStyle       = "-"; 
plotProp.(el_3).LineWidth       = 1; 

N = N+1; 
if N > N_FIELDS; return; end

% -- [H4] Background SDO
el_4 = fieldNames{4};                %// Cyan
%plotProp.(el_4).color           = [0 0.4470 0.7410];
plotProp.(el_4).color           = [034,000,204]/255; %Dark blue
plotProp.(el_4).LineStyle       = ":"; 
plotProp.(el_4).LineWidth       = 1.5;

N = N+1; 
if N > N_FIELDS; return; end

% -- [H5] 1-Step Prespike (Local) Markov
el_5 = fieldNames{5};               %// Black
plotProp.(el_5).color           = [000,000,000]/255; 
plotProp.(el_5).LineStyle       = '-'; 
plotProp.(el_5).LineWidth       = 1; 

N = N+1; 
if N > N_FIELDS; return; end

% -- dSTA-P(x) + Background SDO
el_6 = fieldNames{6};                %// Green
plotProp.(el_6).color           = [021,128,000]/255;
plotProp.(el_6).LineStyle       = "-"; 
plotProp.(el_6).LineWidth       = 1;


N = N+1; 
if N > N_FIELDS; return; end

% -- SDO
el_7 = fieldNames{7};                 %// Orange
plotProp.(el_7).color           = [0.8500 0.3250 0.0980];
plotProp.(el_7).LineStyle       = "-"; 
plotProp.(el_7).LineWidth       = 2;

N = N+1; 
if N > N_FIELDS; return; end

%% RNG the remaining; 
    
rngIDX = N:N_FIELDS; 
nRNG = length(rngIDX); 

cArray = rgb_colorGen(nRNG); 
for ri = rngIDX
    rn = (rngIDX == ri); 
    plotProp.(fieldNames{ri}).color     = cArray(rn,:); 
    plotProp.(fieldNames{ri}).LineStyle = "-"; 
    plotProp.(fieldNames{ri}).LineWidth = 1; 
end


end