%% xtDataCell Class (OOP) - V2
% Public class for manipulating X(t) and interconverting. 
% Designed for use within the SDO Analysis Toolkit

% xtDataCell class used here to contain/operate on time series type data;  

% This has been reduxed to simplify and consolidate calls.

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


classdef xtDataCell2 < handle & matlab.mixin.Copyable 
    %% 'Inherited Properties'
    properties
        data            dataCell.primaryData
        stateMap        dataCell.stateMap
        linearTransform dataCell.linearTransformer
    end
    properties(Dependent)
        % // These are piped from composed classes; 
        nChannels
        nTrials
        sensor
    end
    
    properties (Hidden, Dependent)
        % // Internal Flags for Stability
        discretizedData
        definedState
        sampledData
    end
        
    methods
        %% __ CONSTRUCTOR
        function obj = xtDataCell2(N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS    {mustBeInteger} = 0; 
                N_CHANNELS  {mustBeInteger} = 0; 
            end            
            obj.data            = dataCell.primaryData('xtData',N_TRIALS, N_CHANNELS); 
            obj.stateMap        = dataCell.stateMap(); 
            obj.linearTransform = dataCell.linearTransformer(N_CHANNELS); 
        end
        %% Dependent/Dynamic Properties; 
        function LI = get.discretizedData(obj)
            LI = false; 
            if ~isempty(obj.data.data{1,1}(1).stateSignal)
                LI = true; 
            end
        end
        % Wrapper pipe
        function LI = get.sampledData(obj)
            LI = obj.data.sampledData; 
        end
        %-------------------------------
        function nTrials = get.nTrials(obj)
            nTrials = obj.data.nTrials; 
        end
        %-------------------------------
        function nChannels = get.nChannels(obj)
            nChannels = obj.data.nChannels; 
        end
        %-----------------------------
        function sensor = get.sensor(obj)
            sensor = obj.data.sensor; 
        end
        %------------------------------
        function LI = get.definedState(obj)
            LI = obj.stateMap.definedState; 
        end
        %% __ Populate/Import
        function obj = import(obj,dataHolder, FIELDNAME)
            arguments
                obj
                dataHolder
                FIELDNAME = 'envelope'; 
            end
            %
            obj.data.import(dataHolder, inputname(2)); 
            obj.data.dataType       = 'xtData';
            obj.data.dataField      = FIELDNAME;
            %
            obj.stateMap.getChannelAmp(obj.data); 
            obj.linearTransform = dataCell.linearTransformer(obj.data.nChannels); 
        end
        
        %% OPERATION METHODS
        % __ RESAMPLE SIGNAL FREQUENCY
        function obj = resample(obj, DESIRED_HZ, DATAFIELD) 
            arguments
                obj
                DESIRED_HZ double   = obj.fs; 
                DATAFIELD char      = obj.data.dataField; 
            end
            obj.data.resample(DESIRED_HZ, DATAFIELD); 
        end
        
        % __ DISCRETIZE (Prerequsite for Pxt-mapping)
        function obj = discretize(obj, vars)
            arguments
                obj
                vars.dataField = obj.data.dataField; 
                vars.allowClipping = 1; 
            end
            % Call to support classes; 
            obj.stateMap.getChannelAmp(obj.data);
            obj.stateMap.buildStateMap();
            obj.data = obj.stateMap.discretizeSignal(obj.data, 'dataField', vars.dataField);
            
        end

        % __ FILTER 
        % // Not preferred here (ideally  upstream), but allows JIT operations
        function obj = filter(obj, FILTERTYPE, N_POINTS, F_VAR,vars)
            arguments
                obj
                FILTERTYPE {mustBeMember(FILTERTYPE, {'notch', ...
                    'notchRMS', 'triRMSmov', 'trirmsmov','mov', ...
                    'gaussmov', 'trimov', 'expmov', ...
                    'rmsmov','bandpass', 'highpass', 'lowpass',...
                    'butter', 'emgButter'})}
                N_POINTS
                F_VAR = 1; %auxillary variable for ffilt
                vars.datafield = 'raw'; % to filter
            end
            
            obj.data.filter(FILTERTYPE, N_POINTS, F_VAR, 'dataField', vars.datafield); 
        end
        
        function obj = resetEnvelope(obj)
           %// Quick way to reset the 'envelope' field in the xtdc by
           %re-populating with the 'raw' field; 
           xt_raw = obj.getTensor(1:obj.nChannels,1:obj.nTrials, "DATAFIELD",'raw'); 
           obj.data.importTensor(xt_raw); 
        end

        % __ BIT-WISE FUNCTION OPERATION (Between or within class)
        function obj = bsxop(obj, functionHandle,xtdc) 
            arguments
                obj
                functionHandle function_handle 
                xtdc xtDataCell = []; 
            end
            % --> take one dc operation by the other dc
            
            if ~xtdc.sampledData %(generated by argument parse...}
                %// This is a SINGLE function applied to to the elements; 
                xtTen = obj.getTensor; 
                xtTenOut = functionHandle(xtTen); 
                obj.importTensor(xtTenOut); 
                return
            end
            %// ELSE: Apply BETWEEN two tensors; 

            xtTen1 = obj.getTensor; 
            xtTen2 = xtdc.getTensor; 
            
            % __ Only take overlap of B in A, if A and B are not equal
            if ~all(size(xtTen1) == size(xtTen2))
                disp("WARNING: Datafield sizes are not identical."); 
                %// need to mod xtTen1 to fit xtTen2 ... 
                N_DIMS = ndims(xtTen1); 
                if N_DIMS == 2 
                    N_TEN_TR = 1; 
                    [N_TEN_CH, ~] = size(xtTen1); 
                    xtTen1 = reshape(xtTen1, 1, N_TEN_CH,[]); 
                else
                    [N_TEN_TR, N_TEN_CH, ~] = size(xtTen1);
                end
                %___
                xtTen2_buff = zeros(size(xtTen1)); 
                for tr = 1:N_TEN_TR
                    for ch = 1:N_TEN_CH
                        xt1Len = length(xtTen1(tr,ch,:)); 
                        xtTen2_buff(tr,ch,:) = xtTen2(tr,ch,1:xt1Len);
                    end
                end
                xtTen2 = xtTen2_buff; 
            end
            % __ Array Operation
            xtTenNet = bsxfun(functionHandle, xtTen1, xtTen2); 
            obj.importTensor(xtTenNet); 
            obj.stateMapping.getChannelAmp; 
        end
        
        %% Auxillary Operation
        function obj = importTensor(obj, ten, vars)
            % Repopulate data using supplied 2-3D Tensor; 
            arguments
                obj 
                ten double
                vars.useChannels    {mustBeInteger} = 1:obj.nChannels; 
                vars.useTrials      {mustBeInteger} = 1:obj.nTrials; 
                vars.datafield      char = obj.dataField;
                vars.conform_method char {mustBeMember(vars.conform_method, {'pad', 'nanpad', 'trim'})} = 'trim';                 
            end

            if (obj.nChannels == 0) && (obj.nTrials == 0)
                %// naive cell
                [obj.nChannels, ~, obj.nTrials] = size(ten); 
                vars.useTrials      = 1:obj.nTrials;
                vars.useChannels    = 1:obj.nChannels; 
            end
            % for now, just pass; 
            obj.data  = obj.data.importTensor(ten, ...
                'useChannels', vars.useChannels, ...
                'useTrials', vars.useTrials, ...
                'datafield', vars.datafield, ... 
                'conform_method', vars.conform_method);
            %
            obj.stateMapping.getChannelAmp;     
        end
        
        %% DATA Extraction Methods
        function ten = getTensor(obj, useChannels, useTrials, vars)
            %// public implementation of superclass method
            arguments
                obj
                useChannels         double = 1:obj.nChannels; 
                useTrials           double = 1:obj.nTrials; 
                vars.datafield      char = obj.data.dataField;
                vars.conform_method char {mustBeMember(vars.conform_method, {'pad', 'nanpad', 'trim'})} = 'pad'; 
            end
            %
            ten = obj.data.getTensor(obj, useChannels, useTrials, ...
                'datafield', vars.datafield, 'conform_method', vars.conform_method); 
        end

        function obj = subsample(obj, useTrials, useChannels)
            arguments
                obj
                useTrials           double = 1:obj.data.nTrials; 
                useChannels         double = 1:obj.data.nChannels; 
            end
            if ~obj.data.sampledData 
                disp("No Data sampled in xtDataCell"); 
                return
            end
            
            obj.data.subsample(useTrials, useChannels); 
            obj.linearTransform.subsample(useChannels); 

        end
                % Added 8.29.2024
        % -->> I should migrate this to vcat?
        function obj = combineTrials(obj, useTrials)
            arguments
                obj
                useTrials = 1:obj.nTrials; 
            end
            obj = dataCell.manipulate.concatenateTrials(obj, useTrials); 
        end
        %-----------------------------------------%
        function [obj] = hcat(obj, dcList) 
             arguments
                obj
                dcList % i.e. a {bracketed cell}
            end
            if ismember(class(dcList), 'xtDataCell')
                dcList = {dcList}; 
            end
             for c = 1:length(dcList)
                dc = dcList{c}; 
                obj.data.hcat(dc.data); 
             end
        end
        %-----------------------------------------%
        function [obj] = vcat(obj, dcList) %varargin)
            arguments
                obj
                dcList % i.e. a {bracketed cell}
            end
            if ismember(class(dcList), 'xtDataCell')
                dcList = {dcList}; 
            end
            for c = 1:length(dcList)
                dc = dcList{c}; 
                obj.data.vcat(dc.data); 
            end
        end

        % __ Extract data from 'data' using indexed positions. 
        function values = getValuesAtIndices(obj, indices, vars)
            arguments
                obj
                indices = []; 
                vars.useChannels = 1:obj.nChannels;%[]; 
                vars.useTrials  = 1:obj.nTrials; %[]; 
                vars.dataField {mustBeMember(vars.dataField, {'envelope', 'raw', 'offset', 'stateSignal', 'times'})} = obj.dataField; 
            end
            %--> Pass out; This may be redundant
            values = obj.data.getValuesAtIndices(indices, ...
                'useChannels', vars.useChannels, 'useTrials', vars.useTrials, ...
                'dataField', vars.dataField); 
        end    

        %% ___ Plotter/ Visualization Methods; 
        function plot(obj, useTrials, useChannels, offset, vars)
            arguments
                obj
                useTrials   double = 1:obj.nTrials; 
                useChannels double = 1:obj.nChannels;  
                offset      double = [];  
                vars.datafield char = obj.data.dataField; 
                vars.trialTicks {mustBeNumericOrLogical} = 0; 
            end
            
            obj.data.plot(useTrials,useChannels, offset, ...
                'dataField', vars.datafield, 'trialTicks', vars.trialTicks);
        end

    end
end