%% xtDataCell Class (OOP)
% Class for manipulating X(t) and interconverting. 
% Designed for use within the SDO Analysis Toolkit

% xtDataCell class used here to contain/operate on time series type data; 

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


classdef xtDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass & dataCell.dependencies.primaryData
    %% 'Inherited Properties'
        %data                = []; 
        %metadata            = []; 
        %nTrials             {mustBeInteger} = 0; 
        %nChannels           {mustBeInteger} = 0; 
        %sensor              = []; 
        %fs                  double {mustBeNonnegative} = 0
        %dataField           = []; 
    properties
        trTimeLen           = []; 
        dataSource          = []; 
        % __ Ranging / Discretization Vars; 
        channelAmpMax       = []; %holder for [ch x tr] dynamic max amplitude
        channelAmpMin       = []; %holder for [ch x tr] dynamic min amplitude
        mapMethod           char {mustBeMember(mapMethod, {'linear', 'log', 'linearsigned', 'logsigned'})} = 'log'; 
        maxMode             char {mustBeMember(maxMode, {'pTrial','xTrialxSeg'})} = 'xTrialxSeg'; %reserved for eventual other methods
        nBins               {mustBeInteger, mustBeNonnegative} = 20; 
        %__ Descriptive
        weightMatrix        = 0; %// for describing the relationship between components; 
        nActivationsUsed    {mustBeInteger, mustBeNonnegative} = 0; 
        decomposeMethod     char {mustBeMember(decomposeMethod, {'pca', 'ica'})} = 'pca';
    end
    properties (Hidden, Dependent)
        % // Internal Flags for Stability
        discretizedData
    end

    methods
        %% Dependent/Dynamic Properties; 
        function LI = get.discretizedData(obj)
            LI = false; 
            if ~isempty(obj.data{1,1}(1).stateSignal)
                LI = true; 
            end
        end

        %% __ CONSTRUCTOR
        function obj = xtDataCell(N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS    {mustBeInteger} = 0; 
                N_CHANNELS  {mustBeInteger} = 0; 
            end
            S = dataCell.constructors.getXtDataHolder(N_TRIALS, N_CHANNELS); 
            obj.weightMatrix = eye(N_CHANNELS); 
            obj.data        = S(1,:); 
            obj.metadata    = S(2,:); 
            obj.nTrials     = N_TRIALS; 
            obj.nChannels   = N_CHANNELS; 
            obj.channelAmpMax = zeros(N_CHANNELS, N_TRIALS); 
            obj.channelAmpMin = zeros(N_CHANNELS, N_TRIALS); 
        end
        %% __ Populate/Import
        function obj = import(obj,dataHolder, FIELDNAME)
            arguments
                obj
                dataHolder
                FIELDNAME = 'envelope'; 
            end

            %// Grab from the standard 'xtDataCell' cell-struct struct;
            [~, obj.nTrials] = size(dataHolder); 
            
            obj.nChannels   = length(dataHolder{1,1}); 
            obj.data        = dataHolder(1,:); 
            try
                obj.metadata    = dataHolder(2,:);
            catch
                disp("WARNING! Metadata not imported"); 
                obj.metadata    = cell(size(obj.data)); 
            end
            % -->> TODO: We will need to pass a validation here; 
            try
                obj.sensor   = {dataHolder{1,1}.sensor};
            catch
                %// (depreciated) legacy field
                obj.sensor  = {dataHolder{1,1}.electrode}; 
            end
            obj.fs          = dataHolder{1,1}.fs; 
            obj.dataField   = FIELDNAME; 
            obj.dataSource  = inputname(2); 
            obj.trTimeLen = zeros(1,obj.nTrials); 
            for tr=1:obj.nTrials
                if ~isempty(dataHolder{1,tr}(1).times)
                    obj.trTimeLen(tr) = dataHolder{1,tr}(1).times(end); 
                else
                    obj.trTimeLen(tr) = 0; 
                end
                % __ 
            end 
            obj.setChannelRange; %reset ranges; 
            obj.weightMatrix = eye(obj.nChannels); 
        end
        
        %% OPERATION METHODS
        % __ RESAMPLE SIGNAL FREQUENCY
        function obj = resample(obj, DESIRED_HZ, DATAFIELD) 
            arguments
                obj
                DESIRED_HZ double   = obj.fs; 
                DATAFIELD char      = obj.dataField; 
            end
            if ~obj.sampledData 
                disp("No Data sampled in xtDataCell"); 
                return
            end
            %// Up/Down Sample the xtDC to a different Hz; 
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    xt_in = obj.data{1,tr}(ch).(DATAFIELD); 
                    xt_out = resampleXtToHz(xt_in, obj.fs, DESIRED_HZ); 
                    % -- Writeout in place
                   obj.data{1,tr}(ch).(DATAFIELD) = xt_out; 
                   obj.data{1,tr}(ch).fs = DESIRED_HZ; 
                end
            end
            obj.fs = DESIRED_HZ; 
        end
        % __ DISCRETIZE (Prerequsite for Pxt-mapping)
        function obj = discretize(obj, vars)
            arguments
                obj
                vars.dataField = obj.dataField; 
                vars.allowClipping = 1; 
            end

           % __ >> Using the observed channel max/min apply a statemapping method;  
           %// generate 'sigLevels', and apply this discretization schema
           %to xtData
            if ~obj.sampledData 
                disp("No Data sampled in xtDataCell"); 
                return
            end           
           for ch = 1:obj.nChannels
               xtMaxArr = obj.channelAmpMax(ch,:); 
               xtMinArr = obj.channelAmpMin(ch,:); 
                
               switch obj.maxMode
                   case {'xTrialxSeg'}
                       sigLv = pxTools.getXtSignalLevels(max(xtMaxArr), min(xtMinArr), obj.nBins, obj.mapMethod); 
                       sigArr = repmat(sigLv, obj.nTrials,1); 
                   case {'pTrial'}
                       sigArr    = zeros(obj.nTrials, obj.nBins+1); 
                       %sigArr   = zeros(obj.nBins+1, obj.nTrials);
                       for tr = 1:obj.nTrials
                           sigLv = pxTools.getXtSignalLevels(xtMaxArr(tr), xtMinArr(tr), obj.nBins, obj.mapMethod); 
                           sigArr(tr,:) = sigLv; 
                       end
               end
               if vars.allowClipping
                   %// assign all points, no nans allowed. 
                    sigArr(:,1)     = -inf; 
                    sigArr(:,end)   = inf; 
               end

               % ____ Write-In
               for tr = 1:obj.nTrials
                    obj.data{1,tr}(ch).stateSignal  = discretize(obj.data{1,tr}(ch).(vars.dataField), sigArr(tr,:)); 
                    obj.data{1,tr}(ch).signalLevels    = sigArr(tr,:);  
               end
           end
        end

        % __ FILTER 
        % // Not preferred here (ideally  upstream), but allows JIT operations
        function obj = filter(obj, FILTERTYPE, N_POINTS, F_VAR)
            arguments
                obj
                FILTERTYPE {mustBeMember(FILTERTYPE, {'notch', ...
                    'notchRMS','mov', 'gaussmov', 'trimov', 'expmov', ...
                    'rmsmov','bandpass', 'butter', 'emgButter'})}
                N_POINTS
                F_VAR = 1; %auxillary variable for ffilt
            end
            if ~obj.sampledData 
                disp("No Data sampled in xtDataCell"); 
                return
            end
            xtData = getTensor(obj); 
            xtData2 = xtData; 
            for tr = 1:obj.nTrials 
                for m = 1:obj.nChannels
                    % __ callAFilter 
                    %// callAFilter filters on [1xN] Doubles
                    xt  = squeeze(xtData(m,:,tr)); 
                    fxt = callAfilter(xt, FILTERTYPE, obj.fs,  'nPoints', N_POINTS, 'auxVar', F_VAR); 
                    xtData2(m,:,tr) = fxt; 
                end
            end
            obj.importTensor(xtData2); 
        end

        % Added 8.29.2024
        function obj = concat(obj, useTrials)
            arguments
                obj
                useTrials = 1:obj.nTrials; 
            end
            obj = dataCell.manipulate.concatenateTrials(obj, useTrials); 
        end
        
        function obj = resetEnvelope(obj)
           %// Quick way to reset the 'envelope' field in the xtdc by
           %re-populating with the 'raw' field; 
           xt_raw = obj.getTensor(1:obj.nChannels,1:obj.nTrials, "DATAFIELD",'raw'); 
           obj.importTensor(xt_raw); 
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
            obj.setChannelRange; 
        end
        
        % __ explicit method for setting min/max channel amplitude.
        % Possibly temporary, as we don't know if it would make more sense
        % to make this dynamic or not
        function obj = setChannelRange(obj)
            maxV = zeros(obj.nChannels,obj.nTrials); 
            minV = zeros(obj.nChannels,obj.nTrials); 
            dataField = obj.dataField; 
            for tr = 1:obj.nTrials
                for ch = 1:obj.nChannels
                    maxV(ch,tr) = max(obj.data{1,tr}(ch).(dataField)); 
                    minV(ch,tr) = min(obj.data{1,tr}(ch).(dataField)); 
                end
            end
            obj.channelAmpMax = maxV; 
            obj.channelAmpMin = minV; 
        end

        function obj = setWeightMatrix(obj, METHOD)
            arguments
                obj
                METHOD char {mustBeMember(METHOD, {'ica', 'pca', 'max', 'std'})}= obj.decomposeMethod; 
            end
            % The 'weight matrix' here is a left premultiplication matrix
            % of form [Components] = [Weight]*[xtData], where xtData is a
            % 'nChannels' by 'nObservations' array
          
            nm_cell = cell(1, obj.nChannels); 
            switch METHOD
                % -- Temporary; ts-ICA has trialwise optimization -- 
                case {'ica'}
                    xtS = obj.data;
                    xt = cellstructvcat(xtS, obj.dataField);
                    %// Nan-pad here to fill size, as ts_ica ignores Nans
                    %for calculation of WAS
                    %xt = obj.getTensor(1:obj.nChannels, 1:obj.nTrials, 'CONFORM_METHOD','nanpad'); 
                    [~, ~, ~, W, A, S, ~, ~] = ts_ica(xt, ...
                        'decimate', 1, 'verbose', 1); 
                    obj.weightMatrix = W*A*S; 
                case {'pca', 'max'}
                    xt = getTensor(obj); 
                    xtArr = reshape(xt, obj.nChannels, [], 1); %2D; 
                     [~, W] = iterativeVectorDecomposition(xtArr, METHOD); 
                     obj.weightMatrix = W;

                case {'std'}
                    xt = getTensor(obj); 
                    %W = zeros(obj.nChannels); 
                    V1 = std(xt, [], 3); 
                    V0 = mean(V1,2); 
                    obj.weightMatrix = diag(1./V0); 
            end
            obj.nActivationsUsed = obj.nChannels; 
        end

        function obj = applyLinearTranform(obj, W, level)
            arguments
                obj 
                W = obj.weightMatrix; 
                level {mustBeNumericOrLogical} = 1; 
            end
            % // uses the linear transformation matrix to apply a method


            % __ Uses the weighting matrix to iteratively transform the envelope
            % __ 'level' used to reset baseline for a PC/IC to 0; TODO
            
            % -- Use for-loop rather than tensor here to avoid padding; 
            
            for tr = 1:obj.nTrials
                %// 2D Array; 
                xtData = obj.getTensor(1:obj.nChannels, tr); 
                compData = W*xtData; 
                obj.importTensor(compData, "useChannels", 1:obj.nChannels, "useTrials", tr); 
                % // Rename
                for ch = 1:obj.nChannels
                    obj.data{1,tr}(ch).sensor = strcat("Comp_", num2str(ch)); 
                end
            end
            nm_cell = cell(1, obj.nChannels); 
            for ch = 1:obj.nChannels
                nm_cell{ch} = strcat('CA_', num2str(ch)); 
            end
            obj.sensor = nm_cell; 


        end

        function obj = applyWeightVectorTransform(obj, W, level)
            % // DEPRECIATED NOMECLATURE
            arguments
                obj
                W = obj.weightMatrix; 
                level {mustBeNumericOrLogical} = 1; 
            end
            
            disp("Depreciated Nomeclature. Use 'applyLinearTransform' Instead"); 
            obj = applyLinearTranform(obj, W, level); 

        end
        
        %% Auxillary Operation
        function obj = importTensor(obj, ten, vars)
            % Repopulate data using supplied 2-3D Tensor; 
            arguments
                obj 
                ten double
                vars.useChannels    {mustBeInteger} = 1:obj.nChannels; 
                vars.useTrials      {mustBeInteger} = 1:obj.nTrials; 
                vars.DATAFIELD      char = obj.dataField;
                vars.CONFORM_METHOD char {mustBeMember(vars.CONFORM_METHOD, {'pad', 'nanpad', 'trim'})} = 'trim';                 
            end

            if (obj.nChannels == 0) && (obj.nTrials == 0)
                %// naive cell
                [obj.nChannels, ~, obj.nTrials] = size(ten); 
                vars.useTrials      = 1:obj.nTrials;
                vars.useChannels    = 1:obj.nChannels; 
            end

            N_USE_CH = length(vars.useChannels); 
            N_USE_TR = length(vars.useTrials); 

            trLenPt = ceil(obj.trTimeLen*obj.fs+1); 

            N_TEN_DIM = ndims(ten); 
            if N_TEN_DIM == 3
                [N_TEN_CH, ~, N_TEN_TR] = size(ten); 
            elseif N_TEN_DIM == 2
                N_TEN_TR = 1; 
                if N_USE_CH == 1
                    %// Replace one channel across trials; 
                    N_TEN_CH = N_USE_CH; 
                    [sz_x,sz_y] = size(ten); 
                    if sz_x == N_USE_TR
                        ten = reshape(ten', 1, [], N_USE_TR); 
                    elseif sz_y == N_USE_TR
                        ten = reshape(ten, 1, [],N_USE_TR); 
                    else
                        error("Size of Input Tensor does not match expected parsing parameters"); 
                    end
                elseif N_USE_TR == 1
                    N_TEN_TR = N_USE_TR; 
                    [sz_x,sz_y] = size(ten); 
                    if sz_x == N_USE_CH
                        N_TEN_CH = sz_x; 
                        ten = reshape(ten, N_USE_CH, [], 1); 
                    elseif sz_y == N_USE_CH
                        N_TEN_CH = sz_y; 
                        ten = reshape(ten', N_USE_CH, [], 1); 
                    else
                        error("Size of Input Tensor does not match expected parsing parameters"); 
                    end
                end
            else
                error("Size of Input Tensor does not match expected parsing parameters"); 
            end

            for tri = 1:N_TEN_TR
                tr = vars.useTrials(tri); 
                for chi = 1:N_TEN_CH
                    ch = vars.useChannels(chi); 
                    if N_TEN_DIM > 2
                        xt = squeeze(ten(ch,:,tr));
                    else
                        xt = ten(ch,:); 
                    end
                    xtLen = length(xt); 
                    if xtLen > trLenPt(tr) 
                        % ___ TRIM
                        xtLen = trLenPt(tr); 
                    elseif trLenPt(tr) < xtLen
                        % __ PAD; 
                        xt = [xt, zeros(1, trLenPt-xtLen)]; 
                    end
                    obj.data{1,tr}(ch).(obj.dataField) = xt(1:xtLen); 
                    % -->> Regenerate min/max; 
                end
            end
            obj.setChannelRange; 
        end
        
        %% DATA Extraction Methods
        function ten = getTensor(obj, useChannels, useTrials, vars)
            %// public implementation of superclass method
            arguments
                obj
                useChannels         double = 1:obj.nChannels; 
                useTrials           double = 1:obj.nTrials; 
                vars.DATAFIELD      char = obj.dataField;
                vars.CONFORM_METHOD char {mustBeMember(vars.CONFORM_METHOD, {'pad', 'nanpad', 'trim'})} = 'pad'; 
            end
            if ~obj.sampledData 
                disp("No Data sampled in xtDataCell"); 
                ten = []; 
                return
            end    

            ten = getTensor@dataCellSuperClass(obj, useChannels, useTrials, ...
                'DATAFIELD', vars.DATAFIELD, 'CONFORM_METHOD', vars.CONFORM_METHOD); 
        end

        function obj = subsample(obj, useTrials, useChannels)
            %// public implementation of superclass method
            arguments
                obj
                useTrials           double = 1:obj.nTrials; 
                useChannels         double = 1:obj.nChannels; 
            end
            if ~obj.sampledData 
                disp("No Data sampled in xtDataCell"); 
                return
            end   
            obj = subsample@dataCellSuperClass(obj, useTrials, useChannels); 
            obj.channelAmpMax = obj.channelAmpMax(useChannels, useTrials); 
            obj.channelAmpMin = obj.channelAmpMin(useChannels, useTrials); 
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
            % __ Pre-parse
            if ~iscell(indices)
                % Evaluate time points across ALL trials?? 
                indices = repelem({indices}, 1, length(vars.useTrials));  
            end
            if isempty(vars.useChannels)
                vars.useChannels = 1:obj.nChannels; 
            end
            if isempty(indices)
                %// pass to 'getTensor' instead
                values = obj.getTensor(vars.useChannels, vars.useTrials); 
                return
            end
            %____________
            % {1 x N} indices can refer to either TRIAL indices, or CHANNEL indices...
            % we will need to refer between the two.
            
            N_USE_TRIALS    = length(vars.useTrials); 
            N_USE_XT_CH     = length(vars.useChannels);
            
            % Ideally, we want to get the output as a {N_CHANNELS x N_TRIALS} cell of
            % lookup values 
            
            values = cell(N_USE_XT_CH, N_USE_TRIALS);
            for tri = 1:N_USE_TRIALS
                tr = vars.useTrials(tri); 
                if isempty(indices{tr})
                    continue
                end
                for chi = 1:N_USE_XT_CH
                    ch = vars.useChannels(chi); 
                    % __ Iterative Lookup
                    values{chi,tri} = obj.data{1,tr}(ch).(vars.dataField)(indices{tr}); 
                    if (size(indices{tri},1) >1) && (size(values{chi,tri},1) == 1)
                        % deal with transposed columns
                        values{chi,tri} = values{chi,tri}'; 
                    end
                end
            end
           
        end

        %% __ Write xtdata to a CSV file
        % __>> Allow for a tidy data format. 
        %{
        function write2csv()
                writematrix
        end
        %}
        %% ___ Plotter/ Visualization Methods; 
        function plot(obj, useTrials, useChannels, OFFSET, vars)
            arguments
                obj
                useTrials   double = 1:obj.nTrials; 
                useChannels double = 1:obj.nChannels;  
                OFFSET      double = [];  
                vars.datafield char = obj.dataField; 
                vars.trialTicks {mustBeNumericOrLogical} = 0; 
            end
            if ~obj.sampledData 
                disp("No Data sampled in xtDataCell"); 
                return
            end
            DATAFIELD = vars.datafield; 
            N_PLOT_TRIALS = length(useTrials); 
            N_PLOT_ROWS = length(useChannels); 
            if N_PLOT_TRIALS > 1
                dataCellArr = cellstructhcat(obj.data(1,useTrials), DATAFIELD); 
            else
                dataCellArr = {obj.data{1,useTrials}(:).(DATAFIELD)}'; 
            end
            dataArr = cellvcat(dataCellArr(useChannels,:)); 
            xtDataCell.plot_with_offset(dataArr, OFFSET); 
            %
            if ~isempty(OFFSET)
                offset = OFFSET; 
            else
                offset = 0.5*max( abs(diff(dataArr,1)), [], 'all'); 
            end
            %__ Probably useful for a parser here
            if vars.trialTicks
                trPopNum = obj.trTimeLen(useTrials); 
                xMin = min( -(N_PLOT_ROWS-1)*offset+dataArr(N_PLOT_ROWS,:)); 
                xMax = max(dataArr(1,:)); 
                for tr = 1:N_PLOT_TRIALS
                    t0 = round(sum(trPopNum(1:tr))*obj.fs); 
                    line([t0,t0], [xMin, xMax], 'lineStyle', '--', 'color', 'k'); 
                    text(t0-trPopNum(tr)*obj.fs, xMin, strcat("Trial #", num2str(useTrials(tr)) )); 
                end            
            end
            %___ 
            xticklabels(xticks/obj.fs); 
            xlabel("Time (S)");      
            if N_PLOT_ROWS > 1
                nameDist = -offset*(N_PLOT_ROWS-1):offset:0; 
                yticks(nameDist); 
                yticklabels(flip(obj.sensor(useChannels))); 
            end
        end

        function biplot(obj, useComps) % overload
            arguments
                obj
                useComps = 1:3; 
            end
            if length(useComps) > obj.nChannels 
                useComps = intersect(useComps, 1:obj.nChannels); 
            end
            if length(useComps) > 3
                disp("Warning, only the first three component dimensions are displayed."); 
                useComps = useComps(1:3); 
            end
            N_COMPS = length(useComps); 
            figure; 
            biplot(obj.weightMatrix(useComps,:)'); %transpose due to our convention
            title(strcat("Headings for components: ", num2str(useComps))); 
            xlabel(strcat("Component ", num2str(useComps(1)))); 
            if N_COMPS > 1
                ylabel(strcat("Component ", num2str(useComps(2)))); 
            end
            if N_COMPS > 2
                zlabel(strcat("Component " , num2str(useComps(3))));
            end
        end


    end
    methods (Static)
        % __ Generally used plotter between channels w/ a common offset; 
        function plot_with_offset(dataArr, OFFSET)
            arguments
                dataArr
                OFFSET double = []; 
            end
            N_PLOT_ROWS = size(dataArr, 1); 

            %// Estimate the ideal offset for co-plotting
            if isempty(OFFSET)      
                maxVal = max(max(abs(diff(dataArr,1)))); 
                offset = 0.5*maxVal; 
            else
                offset = OFFSET; 
            end

            figure; 
            
            xMin = inf; 
            xMax = -inf; 
            for m = 1:N_PLOT_ROWS
                xt = dataArr(m,:)-(m-1)*offset; 
                xMax = max(xMax, min(max(xt), offset) ); %up to +1 offset; 
                xMin = min(xMin, max(min(xt), -(m)*offset) );
                if all(isnan(xt))
                    %/ 'missing/nan' values
                    plot(-(m-1)*offset*ones(size(xt)), 'LineStyle',':'); 
                end
                plot(xt); 
                hold on; 
            end
            if m == 1
                %__ single channels get full bandwidth
                xMax = max(xt); 
                xMin = min(xt); 
            end
            % __ Patch 6.8.24

            yvect = -(N_PLOT_ROWS-1)*offset:offset:0; 
            yticks(yvect); 

            % __ 

            %// Rewindow axes to center on data 
            axis([-inf, inf,xMin, xMax]); 
            ylabel(strcat("Channel Offset = ", num2str(offset))); 
            title("Co-Plotted X(t) Data")
        end

    end
end