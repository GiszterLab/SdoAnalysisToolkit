%% prediction Error
% Output Class for carrying the error predictions associated with the
% output measurement of two pxtDataCells
%
% Implemented as a class to reduce overhead w/ predictions. 

%_______________________________________
% Copyright (C) 2024 Trevor S. Smith
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

classdef predictionError < handle
    properties
        errorStruct
        pVal = 0.05; 
        nShuffles = 1000; 
        refName = {}; 
        testName = {}; 
        %
        error_fields = {};      %field names of test statistics
        error_fields_x_state = {}; %fieldnames of test stat CELLS
        %
        errorSig_HH = {}; 
        errorSig_xWise = {}; 
        %
        params = {}; 
        plotProperties = []; 
        hypothesisMatrices = []; 
    end
    methods
        % __ calculate the prediction error 
        function obj = computeError(obj, prd_pxt, obs_pxt, use_obs, vars)
            arguments
                obj
                prd_pxt pxtDataCell  % predictions; 
                obs_pxt pxtDataCell  % ground Truth;
                use_obs = 1; %Numeric, Number for the observed data fit; 
                vars.testSignificance = 1
            end
            
            n_use_obs = length(use_obs); 

            errorS_All = cell(1, n_use_obs); 

            for gg_i = 1:n_use_obs
                gg = use_obs(gg_i);

                if isa(obs_pxt.data, 'cell')
                   PX_NAME = obs_pxt.pxtNames{gg}; 
                   x1PxArr.(obs_pxt.pxtNames{gg})   = obs_pxt.data{gg}; 
                   x1StateArr.(obs_pxt.pxtNames{gg})= pxTools.getXfromPx(obs_pxt.data{gg}, obs_pxt.stateAssignment);  
                else
                   x1PxArr.(obs_pxt.pxtNames)   = obs_pxt.data; 
                   PX_NAME = obs_pxt.pxtNames; 
                   x1StateArr.(obs_pxt.pxtNames)= pxTools.getXfromPx(obs_pxt.data, obs_pxt.stateAssignment);  
                end
    
                for hh = 1:prd_pxt.nPxtTypes
                   pdPxArr.(prd_pxt.pxtNames{hh})       = prd_pxt.data{hh}; 
                   pdStateArr.(prd_pxt.pxtNames{hh})    = pxTools.getXfromPx(prd_pxt.data{hh}, prd_pxt.stateAssignment);  
                end
                
                N_BINS   = prd_pxt.nStates; 
                N_XT_PTS = prd_pxt.nEvents;  
    
                x0StateArr = obs_pxt.xs; 
    
                % We need something like a x(s) in these fields for organizing
                % state-at-spike
    
                %// Here, we assume the px0 is the populated element; 
                
                sFields = fieldnames(pdStateArr); 
    
                errorS = SAT.predict.calcPredictionError(...
                    x0StateArr, x1StateArr.(PX_NAME), pdStateArr, x1PxArr.(PX_NAME), pdPxArr, N_BINS, ...
                    'refName', PX_NAME, ...
                    'nXtPts', N_XT_PTS); 

               errorS_All{gg_i} = errorS; 
                            
            end
                
           if n_use_obs == 1
               %// unwrap cell; 
               errorS_All = errorS_All{1}; 
           end
            %________

           % ++ WARNING: Fragile Calls ++
           scalar_fieldnames = {...
               'L0_running',...
               'L1_running',...
               'L2_running', ...
               'KLD', ...
               'logLikelihood'}; 

           statewise_fieldnames = { ...
               'L0_running_x_state', ...
               'L1_running_x_state', ...
               'L2_running_x_state'}; 
            %
            obj.error_fields = scalar_fieldnames; 
            obj.error_fields_x_state = statewise_fieldnames; 
            % ======================================
           
            % ___ Writeout; 
            
            obj.hypothesisMatrices = prd_pxt.dataMatrices; 
            obj.testName = sFields;  
            obj.refName = PX_NAME; 
            obj.setPlotProperties(); 
            obj.errorStruct = errorS_All; 
            %
            if vars.testSignificance
                % This can be slow with batch processing; 
                obj.testSignificance; 
            end

        end

        function obj = setPlotProperties(obj, fNames)
            arguments
                obj
                fNames cell = []; 
            end
            if isempty(fNames)
                fNames = obj.testName; 
            end
             obj.plotProperties = SAT.predict.assignPlotterProperties(fNames); 
        end

        %___________ Test Significance; 
        
        function obj = testSignificance(obj, alpha)
            arguments
                obj
                alpha = obj.pVal; 
            end


            %TODO: Better integration + function segregation
            % Need to break out the enhanced plotters vs. the significance.
            % 

            % --> Ideally, test for significance before breaking out
            % plotters. 

            [err_pop, err_xwise] = SAT.predict.testSig2(obj.errorStruct, ...
                obj.error_fields, ...
                obj.error_fields_x_state, ...
                "alpha", alpha); 
            %
            obj.pVal = alpha; 
            obj.errorSig_HH = err_pop; 
            obj.errorSig_xWise = err_xwise; 

        end

        %_____________

        function plot(obj,vars)
            arguments
                obj
                vars.saveFig = 0; 
                vars.saveFormat {mustBeMember(vars.saveFormat, {'png', 'svg'})} = 'png';
                vars.saveDirectory = []; 

                % ... 
            end

            %TODO: Add better validation for save dir; 

            SAT.predict.plotErrorStruct(obj.errorStruct, ...
                "alpha",    obj.pVal, ...
                "fill",     0, ...
                "nShuffles", obj.nShuffles, ... 
                'saveDirectory', vars.saveDirectory, ...
                'saveFig',        vars.saveFig, ...
                'saveFormat',       vars.saveFormat, ...
                'plotProperties', obj.plotProperties); 

        end

        function plotMatrices(obj, type, useMatrices)
            arguments
                obj
                type {mustBeMember(type, {'L', 'M'})} = 'L'; 
                useMatrices = 1:length(obj.errorStruct); 
            end

            % __ Will require our external functions... 

            
            mats = cellzcat(obj.hypothesisMatrices'); 
            try
                figure; 
                switch type
                    case 'L'
                        plotSdoStack(mats(:,:,useMatrices));
                    case 'M'
                        for z = 1:size(mats,3)
                            mats(:,:,z) = mats(:,:,z)+eye(length(mats)); 
                        end
                        plotSdoStack(mats(:,:,useMatrices)); 
                end
            catch
                disp("Not Fully Implemented Yet"); 
            end
        end


    end

end

