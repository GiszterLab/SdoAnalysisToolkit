%% dataCell.intervalSampler
% 
% Support Class for drawing intervals from time events
%
% Useful for defining intervals
%
% called by  pxtDataCell

% This is going to be the new method for defining the sampling properties
% from data; used to draw distributions, as necessary. 

% UPGRADES: 
    % --> Here, we should replace the intervals in bins, to intervals in
    % times. 

classdef intervalSampler
    properties
        n_shift = 0; 
        z_delay = 0; 
        t0_nPoints = 20 
        fs = 0; 
        
        
    end
    methods
        
    end
end