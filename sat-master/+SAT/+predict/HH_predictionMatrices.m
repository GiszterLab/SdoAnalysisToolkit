%% HH_predictionMatrices()
%
% Class-Def structure for HH testing
% Reduxed as a lightweight class. 

% TODO: Better call-out handling to existing getH1 :: getH7 methods

%_______________________________________
% Copyright (C) 2025 Trevor S. Smith
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

classdef HH_predictionMatrices < handle & matlab.mixin.Copyable
    properties
        full_matrix_names  = {}; 
        mini_matrix_names  = {}; 
        predictionMatrices = []; 
        H_Struct = []; 
        xtChannel_NO
        xtChannel
        ppChannel_NO
        ppChannel
        type        {mustBeMember(type, {'M', 'L'})} = 'L';
        staMethod   {mustBeMember(staMethod, {'dpx', 'px'})} = 'px';
    end
    properties (Dependent, Hidden)
       calculatedMatrices 
    end
    methods
        function obj = HH_predictionMatrices()
           % Empty Constructor
        end
        %
        function LI = get.calculatedMatrices(obj)
            LI = ~isempty(obj.predictionMatrices); 
        end
        %
        function pd_pxData = predictPx(obj, pxData, useIX)
            arguments
                obj
                pxData dataCell.pxAssigner
                useIX = 7; % Default SDO
            end
            % We'll just run through it all. 
            pd_pxData = copy(pxData); 
            
            L = obj.predictionMatrices(:,:,useIX);

            sdoPredict = @(px) L*px+px; % linear update
            
            pd_pxData.data = cellfun(sdoPredict, pd_pxData.data, 'UniformOutput', 0); 
            
        end        
        %
        % Alternatively; call-out to existing function w/ bundle to depre
        function obj = getPredictionMatrices(obj, sata, XT_CH_NO, PP_CH_NO, vars)
            arguments
                obj
                sata SAT.analyzer
                XT_CH_NO = 1; 
                PP_CH_NO = 1; 
                vars.backgroundSubtraction = 0; 
            end
            % __>> Full Matrix Names here for 'nice names'
            fullNames = {...
                'No Change', ...
                'Gaussian Diffusion', ...
                '(Simple) Spike-Triggered Average', ...
                'Background SDO', ...
                'Markov', ....
                'State-independent STA (dpx) + background', ...
                'Unit SDO + Background SDO'}; 
            
               sFields = {'t0t1', 'gauss', 'STA', 'bck', 'mkv', 'staBck', 'SDO'};
               %
            H_StructS = SAT.predict.getPredictionMatrices2(sata, [], [], XT_CH_NO, PP_CH_NO, ...
                'backgroundSubtraction', vars.backgroundSubtraction); 
               
               %{
            for h = 1:length(sFields) 
                H_StructS.(sFields{h}) = {}; 
            end
            % [H1] T0/T1
            H_StructS.(sFields{1}) = SAT.predict.matrices.getH1(sata.nStates, ...
                "type",obj.type); 
            %--------------------------
            % [H2] Gaussian
            H2_std = min(sata.pxConfig.G_smoothFStdev_Pts, 1); 
            H2_wid = min(sata.pxConfig.G_smoothFWidth_Pts, 1); 
            
            H_StructS.(sFields{2}) = SAT.predict.matrices.getH2(sata.nStates, ...
                "filterStd",  H2_std, ...
                'filterWidth',H2_wid, ...
                'type', obj.type); 
            %---------------------------
            % [H3] STA
            at0 = cellhcat(sata.unitSDO.x0Data.data(XT_CH_NO,:)); 
            at1 = cellhcat(sata.unitSDO.x1Data.data(XT_CH_NO,:));
            H_StructS.(sFields{3}) = SAT.predict.matrices.getH3(sata.nStates, ...
                at0, at1, sata.stateMapping.stateMapping(:, XT_CH_NO, 1), ...
                'type', obj.type, ...
                'method', obj.staMethod); 
            %---------------------------
            % [H4] Background 
            H_StructS.(sFields{4}) = ...
                sata.backgroundSDO.sdo(XT_CH_NO, PP_CH_NO).sdoMatrixNormed; 
            %---------------------------
            % [H5] Markov
            xt0 = sata.stateMapping.discretizeSignalRaw( ...
                cellhcat(sata.unitSDO.x0Data.data(XT_CH_NO, :)), ...
                XT_CH_NO, 1:sata.nTrials); 
            %
            H_StructS.(sFields{5}) = SAT.predict.matrices.getH5(sata.nStates, ...
                xt0,  sata.x1Config.dura_nPoints, ...
                'type', obj.type); 
            %-------------------------
            % [H6] STA+Background  
            nBkdM = sata.backgroundSDO.sdo(1, XT_CH_NO).jointMatrix;
            [~, ~, sta_mMat] = SAT.predict.matrices.getH3(sata.nStates, ...
                at0, at1, sata.stateMapping.stateMapping(:, XT_CH_NO, 1), ...
                'type', obj.type, ...
                'method', 'dpx'); 
            nStaM = SAT.sdoUtils.normsdo(sta_mMat, sta_mMat); 
            HConv = nBkdM*nStaM;
            switch obj.type
                case 'L'
                    mat = HConv - diag(sum(HConv)); 
                case 'M'
                    mat = HConv; 
            end
            H_StructS.(sFields{6}) = mat; 
            %----------------------------
            % [H7] (pass SDO)
            
            if sata.sdoConfig.backgroundSubtraction == 1
                bkdSDO  = sata.backgroundSDO.sdo(XT_CH_NO, PP_CH_NO).sdoMatrix; 
                bkjSDO  = sata.backgroundSDO.sdo(XT_CH_NO, PP_CH_NO).jointMatrix; 
                dSDO    = sata.unitSDO.sdo(XT_CH_NO, PP_CH_NO).sdoMatrix;
                jSDO    = sata.unitSDO.sdo(XT_CH_NO, PP_CH_NO).jointMatrix;
                [L,M] = SAT.sdoUtils.unitplusbackground(bkdSDO,bkjSDO, dSDO, jSDO);
                if 1 == 1
                    H_StructS.(sFields{7}) = L; 
                else
                    H_StructS.(sFields{7}) = M; 
                end
            else
               H_StructS.(sFields{7}) =  sata.unitSDO.sdo(XT_CH_NO, PP_CH_NO).sdoMatrixNormed; 
            end
            %}
            
            %%  -- 
            zArr = zeros(sata.nStates, sata.nStates, length(sFields)); 
            for z = 1:length(sFields)
                zArr(:,:,z) = H_StructS.(sFields{z}); 
            end
            
            % _________ Write out________
            obj.full_matrix_names = fullNames; 
            obj.mini_matrix_names = sFields; 
            obj.predictionMatrices = zArr; 
            obj.H_Struct = H_StructS; 
            obj.xtChannel_NO = XT_CH_NO; 
            obj.ppChannel_NO = PP_CH_NO; 
            % __ // these only ever reference 1x, so we can take these as
            % str/char // 
            obj.xtChannel = sata.unitSDO.xtSensor{XT_CH_NO}; 
            obj.ppChannel = sata.unitSDO.ppSensor{PP_CH_NO};
        end
        %--------------
        %TODO: Various Plotters; 
        % --> hack in from sdoComputer. 
        function f = plot(obj)
            if nargout > 0
                f = SAT.plot.plotSdoStack( obj.predictionMatrices, obj.mini_matrix_names); 
            else
                SAT.plot.plotSdoStack( obj.predictionMatrices, obj.mini_matrix_names); 
            end
        end
        
    end
end

