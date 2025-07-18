%% prediction Error (v2)
% Output Class for carrying the error predictions associated with the
% output measurement of two pxtDataCells
%
% Implemented as a class to reduce overhead w/ predictions ++ plot error
%
% >> TODO: Full synthesis of the predictionMatrix class w/ the error
% element (No reason to really be separate). 

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

classdef predictionError2 < handle & matlab.mixin.Copyable 
    properties
        %------------------
        obs_x0Data      dataCell.intervalSampler
        obs_x1Data      dataCell.intervalSampler
        pd_x1DataCell   cell % {1, 7}; % cell of dataCell.intervalSampler
        %
        obs_px0Data     dataCell.pxAssigner
        obs_px1Data     dataCell.pxAssigner
        pd_px1DataCell  cell % {1,7};  cell of dataCell.intervalSampler
        %
        stateMap        dataCell.stateMap
        %
        %-----------------
        %
        groundTruth % DEPRECATE
        %
        errorStruct
        pVal = 0.05; 
        params              SAT.properties.computerProperties
        predictionMatrices  SAT.predict.HH_predictionMatrices
    end
    properties (Dependent)
        hypothesisMatrices
        nHypotheses
        %
        xtChannel_NO
        xtChannel
        ppChannel_NO
        ppChannel        
    end
    properties (Dependent, Hidden)
        calculatedMatrices
    end
    methods
        % __ calculate the prediction error 
        function obj = predictionError2(P_VAL, N_SHUFF)
            obj.pVal                = P_VAL; 
            obj.nShuffles           = N_SHUFF;
            obj.errorStruct         = SAT.predict.errorStruct_new(7); % number of HH
            obj.predictionMatrices  = SAT.predict.HH_predictionMatrices();
            obj.stateMap            = dataCell.stateMap(); 
        end
        %
        function obj = import(obj, sata, XT_CH_NO, PP_CH_NO)
            arguments
                obj
                sata        SAT.analyzer
                XT_CH_NO
                PP_CH_NO
            end
            % -- Pull from SDO.Analyzer
            obj.obs_x0Data = sata.getxData(...
                XT_CH_NO, PP_CH_NO, 'x0');   
            obj.obs_x1Data = sata.getxData(...
                XT_CH_NO, PP_CH_NO, 'x1');               
            obj.obs_px0Data = sata.getPxData( ...
                XT_CH_NO, PP_CH_NO, 'px0'); 
            obj.obs_px1Data = sata.getPxData( ...
                XT_CH_NO, PP_CH_NO, 'px1'); 
            %
            obj.predictionMatrices.getPredictionMatrices(sata, XT_CH_NO, PP_CH_NO);
            %
            obj.stateMap = sata.stateMapping.subsample([], XT_CH_NO); 
        end
        %-----------------------------
        function HH = get.hypothesisMatrices(obj)
            HH = obj.predictionMatrices.predictionMatrices;
        end
        function n = get.nHypotheses(obj)
            n = size(obj.hypothesisMatrices,3); 
        end
        %------------------------------
        function n = get.xtChannel_NO(obj)
            n = obj.predictionMatrices.xtChannel_NO; 
        end
        %------------------------------
        function n = get.xtChannel(obj)
            n = obj.predictionMatrices.xtChannel; 
        end 
        %-----------------------------
        function n = get.ppChannel_NO(obj)
            n = obj.predictionMatrices.ppChannel_NO; 
        end
        %---------------------------
        function n = get.ppChannel(obj)
            n = obj.predictionMatrices.ppChannel; 
        end        
        %----------------------------
        function LI = get.calculatedMatrices(obj)
            LI = obj.predictionMatrices.calculatedMatrices; 
        end
        %------------------------------
        function pd_px = predictPxRaw(obj, pxDataRaw, useIX)
            arguments
                obj                
                pxDataRaw double
                useIX = 7; % Default SDO
            end
            % method for predicting post-state; 
            L = obj.hypothesisMatrices(:,:,useIX); 
            pd_px = L*pxDataRaw+pxDataRaw; 
            pd_px = normpdfcol2unity(pd_px); 
        end
        %
        function obj = predictPxError(obj) 
            for s = 1:7
                obj.pd_px1DataCell{s} = ...
                    obj.predictionMatrices.predictPx( obj.obs_px0Data, s); 
            end
            
        end
       %
       
       function obj = bungleSDOStruct(obj)
           1; 
           % TODO: For best parsing w/ deprecated code
       end
       
        % Input prediction error?
        
        % IF we assume that there is only 1x input prediction, then we can
        % make this work; 
        function obj = computeError(obj) %  prd_px, obs_px, use_obs, vars)
            arguments
                obj
            end
            
            % Rebuild
            
            % TODO: State assignment px ---> X
            
            STATE_ASSIGNMENT = 'max'; 
            
            N_BINS      = obj.obs_px0Data.nStates(1); 
            
            xx_x0Data = obj.obs_x0Data.discretize(obj.stateMap); 
            %{
            xx_x1Data = obj.obs_x1Data.discretize(obj.stateMap); 
            
            obs_x0_data = xx_x0Data.data; 
            obs_x1_data = xx_x1Data.data;
            %}
            obs_px1_data = obj.obs_px1Data.data;
            obs_px0_data = obj.obs_px0Data.data; 
            if iscell(obs_px0_data)
                if size(obs_px0_data,2) > 1
                    %{
                    obs_x0_data = cellhcat(obs_x0_data); 
                    obs_x1_data = cellhcat(obs_x1_data); 
                    %}
                    % // We could just just take xs instead...
                    obs_px0_data = cellhcat(obs_px0_data); 
                    obs_px1_data = cellhcat(obs_px1_data); 
                    xx_x0Data    = cellhcat(xx_x0Data.data); 
                    %
                end
                obs_x0_data = pxTools.getXfromPx(obs_px0_data, STATE_ASSIGNMENT); 
                obs_x1_data = pxTools.getXfromPx(obs_px1_data, STATE_ASSIGNMENT);                 
            end
            
            for hh = 1:obj.nHypotheses
                PX_NAME = obj.predictionMatrices.mini_matrix_names{hh};
                dat0 = obj.pd_px1DataCell{hh}; 
                dat = dat0.data; 
                % Flatten? 
                if iscell(dat)
                    if size(dat,2) > 1
                        dat = cellhcat(dat); 
                    end
                end
                %
                pd_px1Arr.(PX_NAME) = dat;
                pd_x1Arr.(PX_NAME) = pxTools.getXfromPx(dat, STATE_ASSIGNMENT); 
            end
           
            errorS = SAT.predict.calcPredictionError(...
                obs_x0_data, ...
                obs_x1_data, ...
                pd_x1Arr, ...
                obs_px1_data, ...
                pd_px1Arr, ...
                N_BINS, ...
                'refName', 'x0', ...
                'nXtPts', size(obs_x0_data,2)); 
                
             1; 


            % ======================================
          
            % Add Ground Truth (X1) for organization; --> We can use the X0
            % from no-change [H1] to infer px0, x0. 
            % //  Redundant; 
            %{
            obj.groundTruth.px = obs_px.data;
            obj.groundTruth.xs = obs_px.xs;  %x0StateArr; %This is actually Xs
            obj.groundTruth.x1 = obs_px.data_x; % this is the pre-spike state. 
            %}
            obj.errorStruct = errorS; 
            % DEPRECATE
            %
            obj.groundTruth.px =    obs_px1_data;
            obj.groundTruth.xs =    xx_x0Data; % state at spike; not state at 0
            obj.groundTruth.x1 =    obs_x1_data; 
            %}
            % ___ Writeout; 
     
            %obj.hypothesisMatrices = prd_pxt.dataMatrices; 
            %{
            obj.testName = sFields;  
            obj.refName = PX_NAME; 
            %}
            obj.setPlotProperties(); 
            %obj.errorStruct = errorS_All; 
            %{
            if vars.testSignificance
                % This can be slow with batch processing; 
                obj.testSignificance; 
            end
            %}
        end

        function obj = setPlotProperties(obj, fNames)
            arguments
                obj
                fNames cell = []; 
            end
            if isempty(fNames)
                %fNames = obj.testName; 
                fNames = obj.predictionMatrices.mini_matrix_names; 
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
        
        function plotMatrix(obj)
            
            obj.predictionMatrices.plot(); 
            
        end

        function plot(obj,vars)
            arguments
                obj
                vars.saveFig = 0; 
                vars.saveFormat {mustBeMember(vars.saveFormat, {'png', 'svg'})} = 'png';
                vars.saveDirectory = []; 
                vars.reference {mustBeMember(vars.reference, {'xs', 'x1'})} = 'x1'; 
            end

            %// TODO: Upgrade this to the new variants
            switch vars.reference
                case 'xs'
                    ref_x = obj.groundTruth.xs; 
                case 'x1'
                    ref_x = obj.groundTruth.x1; 
            end

            %TODO: Add better validation for save dir; 

            SAT.predict.plotErrorStruct(obj.errorStruct, ...
                "alpha",    obj.pVal, ...
                "fill",     0, ...
                "nShuffles", obj.nShuffles, ... 
                'saveDirectory', vars.saveDirectory, ...
                'saveFig',        vars.saveFig, ...
                'saveFormat',       vars.saveFormat, ...
                'plotProperties', obj.plotProperties, ...
                'x1', ref_x); 
        end
        
        %------------------------------------------------------------------
        function plotMatrices(obj, type, useMatrices)
            arguments
                obj
                type {mustBeMember(type, {'L', 'M'})} = 'L'; 
                useMatrices = 1:length(obj.errorStruct); 
            end

            % __ Will require our external functions... 
            
            mats = obj.hypothesisMatrices; 
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

