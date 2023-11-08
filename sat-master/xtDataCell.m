%% xtDataCell Class (OOP)
% Class for manipulating X(t) data. Designed for use within the SDO
% Analysis Toolkit

% xtDataCell class used here to contain time series type data; 

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


classdef xtDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass
    properties
        data                = []; 
        metadata            = []; 
        nTrials             {mustBeInteger} = 0; 
        nChannels           {mustBeInteger} = 0; 
        sensor              = []; 
        fs                  double {mustBeNonnegative} = 0
        trTimeLen           = []; 
        dataField           = []; 
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
    properties (Access = protected) 
        %// for stability
        sampledData = false; 
    end
    methods
        %% __ CONSTRUCTOR
        function obj = xtDataCell(N_TRIALS, N_CHANNELS)
            arguments
                N_TRIALS    {mustBeInteger} = 0; 
                N_CHANNELS  {mustBeInteger} = 0; 
            end
            S = SAT.xtDataHolder_new(N_TRIALS, N_CHANNELS); 
            obj.data        = S(1,:); 
            obj.metadata    = S(2,:); 
            obj.nTrials     = N_TRIALS; 
            obj.nChannels   = N_CHANNELS; 
        end
        %% __ Populate/Import
        function obj = import(obj,dataCell, FIELDNAME)
            arguments
                obj
                dataCell
                FIELDNAME = 'envelope'; 
            end

            %// Grab from the standard 'xtDataCell' cell-struct struct;
            [~, obj.nTrials] = size(dataCell); 
            
            obj.nChannels   = length(dataCell{1,1}); 
            obj.data        = dataCell(1,:); 
            try
                obj.metadata    = dataCell(2,:);
            catch
                disp("WARNING! Metadata not imported"); 
                obj.metadata    = cell(size(obj.data)); 
            end
            % -->> TODO: We will need to pass a validation here; 
            try
                obj.sensor   = {dataCell{1,1}.sensor};
            catch
                %// (depreciated) legacy field
                obj.sensor  = {dataCell{1,1}.electrode}; 
            end
            obj.fs          = dataCell{1,1}.fs; 
            obj.dataField   = FIELDNAME; 
            obj.dataSource  = inputname(2); 
            
            % __ collect dynamic amplitude 
            obj.channelAmpMax = zeros(obj.nChannels, obj.nTrials); 
            obj.channelAmpMax = zeros(obj.nChannels, obj.nTrials); 
            
            obj.trTimeLen = zeros(1,obj.nTrials); 
            for tr=1:obj.nTrials
                if ~isempty(dataCell{1,tr}(1).times)
                    obj.trTimeLen(tr) = dataCell{1,tr}(1).times(end); 
                else
                    obj.trTimeLen(tr) = 0; 
                end
                % __ 
                for ch = 1:obj.nChannels
                    xt = obj.data{1,tr}(ch).(obj.dataField); 
                    try
                        obj.channelAmpMax(ch,tr) = max(xt); 
                        obj.channelAmpMin(ch,tr) = min(xt);
                    catch
                        obj.channelAmpMax(ch,tr) = 0; 
                        obj.channelAmpMin(ch,tr) = 0; 
                    end
                end
            end 
            obj.weightMatrix = eye(obj.nChannels); 
            obj.sampledData = true; 
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
        function obj = discretize(obj)
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
               % ____ Write-In
               for tr = 1:obj.nTrials
                    obj.data{1,tr}(ch).stateSignal  = discretize(obj.data{1,tr}(ch).(obj.dataField), sigArr(tr,:)); 
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
       
        % __ BIT-WISE FUNCTION OPERATION
        function obj = bsxop(obj, xtdc, functionHandle) 
            arguments
                obj
                xtdc xtDataCell
                functionHandle function_handle 
            end
            % --> take one dc operation by the other dc
            
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
        end
        
        function obj = setWeightMatrix(obj, METHOD)
            arguments
                obj
                METHOD char {mustBeMember(METHOD, {'ica', 'pca', 'max'})}= obj.decomposeMethod; 
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
            end
            obj.nActivationsUsed = obj.nChannels; 
        end

        function obj = applyWeightVectorTransform(obj, level)
            arguments
                obj
                level {mustBeNumericOrLogical} = 1; 
            end
            % __ Uses the weighting matrix to iteratively transform the envelope
            % __ 'level' used to reset baseline for a PC/IC to 0; TODO
            
            % -- Use for-loop rather than tensor here to avoid padding; 
            
            for tr = 1:obj.nTrials
                %// 2D Array; 
                xtData = obj.getTensor(1:obj.nChannels, tr); 
                compData = obj.weightMatrix*xtData; 
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
        
        %% Auxillary Operation
        function obj = importTensor(obj, ten, vars)
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
                end
            end
            obj.sampledData = true; 
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
                plot(xt); 
                hold on; 
            end
            %// Rewindow axes to center on data 
            axis([-inf, inf,xMin, xMax]); 
            ylabel(strcat("Channel Offset = ", num2str(offset))); 
            title("Co-Plotted X(t) Data")
        end

    end
end