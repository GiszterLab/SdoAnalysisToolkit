%% xtDataCell Class (OOP)
% Eventual upgrade script for wrapping the xtData, containing the methods
% we need for manipulating these structures w/ increased ease

% xtDataCell class used here to contain time series type data; 

% Trevor S. Smith, 2023
% Drexel University College of Medicine

classdef xtDataCell < handle & matlab.mixin.Copyable & dataCellSuperClass
    properties
        data                = []; 
        metadata            = []; 
        nTrials             {mustBeInteger} = 0; 
        nChannels           {mustBeInteger} = 0; 
        electrode           = []; 
        fs                  double {mustBeNonnegative} = 0
        trTimeLen           = []; 
        dataField           = []; 
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
    methods
        %% __ CONSTRUCTOR
        function obj = xtDataCell(N_TRIALS, N_CHANNELS)
            S = SAT.xtDataHolder_new(N_TRIALS, N_CHANNELS); 
            obj.data        = S(1,:); 
            obj.metadata    = S(2,:); 
            obj.nTrials     = N_TRIALS; 
            obj.nChannels   = N_CHANNELS; 
        end


        %% __ Populate/Import
        function obj = import(obj,dataCell) 
            %// Grab from the standard 'xtDataCell' cell-struct struct;
            [~, obj.nTrials] = size(dataCell); 
            
            obj.nChannels   = length(dataCell{1,1}); 
            obj.data        = dataCell(1,:); 
            try
                obj.metadata    = dataCell(2,:);
            catch
                disp("WARNING! Metadata not imported"); 
                obj.data    = cell(size(obj.data)); 
            end
            % -->> We will need to pass a validation here; 
            obj.electrode   = {dataCell{1,1}.electrode}; 
            obj.fs          = dataCell{1,1}.fs; 
            obj.dataField   = 'envelope'; %temporary for XTDC
            
            % __ collect dynamic amplitude 
            obj.channelAmpMax = zeros(obj.nChannels, obj.nTrials); 
            obj.channelAmpMax = zeros(obj.nChannels, obj.nTrials); 
            
            obj.trTimeLen = zeros(1,obj.nTrials); 
            for tr=1:obj.nTrials
                obj.trTimeLen(tr) = dataCell{1,tr}(1).times(end); 
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
        end
        
        %% OPERATION METHODS
        
        % __ RESAMPLE SIGNAL FREQUENCY
        function obj = resample(obj, DESIRED_HZ, DATAFIELD) 
            arguments
                obj
                DESIRED_HZ double   = obj.fs; 
                DATAFIELD char      = obj.dataField; 
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
        % __ DISCRETIZE (Pre-Req for Pxt-mapping)
        function obj = discretize(obj)
           % __ >> Using the observed channel max/min apply a statemapping method;  
           %// generate 'sigLevels', and apply this discretization schema
           %to xtData
           
           for ch = 1:obj.nChannels
               xtMaxArr = obj.channelAmpMax(ch,:); 
               xtMinArr = obj.channelAmpMin(ch,:); 
                
               switch obj.maxMode
                   case {'xTrialxSeg'}
                       sigLv = pxTools.getXtSignalLevels(max(xtMaxArr), min(xtMinArr), obj.nBins, obj.mapMethod); 
                       sigArr = repmat(sigLv, obj.nTrials,1); 
                   case {'pTrial'}
                       sigArr   = zeros(obj.nBins+1, obj.nTrials);
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
            % __ EXTRACT; OPERATE; REPACKAGE
            
            xtTen1 = obj.getTensor; 
            xtTen2 = xtdc.getTensor; 
            
            % __ Only take overlap of B in A, if A and B are not equal
            if ~all(size(xtTen1) == size(xtTen2))
                disp("WARNING: Datafield sizes are not identical."); 
                %// need to mod xtTen1 to fit xtTen2 ... 
                N_DIMS = ndims(xtTen1); 
                if N_DIMS == 2 
                    N_TEN_TR = 1; 
                    [N_TEN_CH, ~] = size(ten); 
                    xtTen1 = reshape(xtTen1, 1, N_TEN_CH, N_TEN_PT); 
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
            xt = getTensor(obj); 
            xtArr = reshape(xt, obj.nChannels, [], 1); %2D; 
            [~, W] = iterativeVectorDecomposition(xtArr, METHOD); 
            obj.weightMatrix = W; 
            obj.nActivationsUsed = obj.nChannels; 
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
            N_USE_CH = length(vars.useChannels); 
            N_USE_TR = length(vars.useTrials); 

            trLenPt = obj.trTimeLen*obj.fs+1; 

            % OLD !!!
            %// Tensor assumed as [N_TRIALS x N_CHANNELS x N_POINTS] -->
            
            %// TRIM whether to adapt the xtDC to tensor or tensor to xtDC
            
            %// Tensor (now) assumed to be [N_CHANNELS, N_POINTS, N_TRIALS)

            N_TEN_DIM = ndims(ten); 
            if N_TEN_DIM == 3
                [N_TEN_CH, ~, N_TEN_TR] = size(ten); 
            elseif N_TEN_DIM == 2
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
                        ten = rehape(ten', N_USE_CH, [], 1); 
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
                    xt = squeeze(ten(ch,:,tr));
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
        end
        
        %% DATA Extraction Methods
        
        %// Extract a N_Channels x N_Points x N_Trials datatensor
        function ten = getTensor(obj, useChannels, useTrials, vars)
            arguments
                obj
                useChannels         double = 1:obj.nChannels; 
                useTrials           double = 1:obj.nTrials; 
                vars.DATAFIELD      char = obj.dataField;
                vars.CONFORM_METHOD char {mustBeMember(vars.CONFORM_METHOD, {'pad', 'nanpad', 'trim'})} = 'pad'; 
            end
            N_TRIALS    = length(useTrials); 
            N_XT_CH     = length(useChannels);  
            
            switch vars.CONFORM_METHOD
                case {'Pad', 'pad'}
                    TRIM = 0; 
                    %// Zero Pad signals to maximum trial length; 
                    maxTLen = max(obj.trTimeLen(useTrials)); 
                    maxLen = ceil(maxTLen*obj.fs+1/obj.fs); 
                    ten = zeros(N_XT_CH, maxLen, N_TRIALS); 
                case {'nanpad'}
                    TRIM = 0; 
                    maxTLen = max(obj.trTimeLen(useTrials)); 
                    maxLen = ceil(maxTLen*obj.fs+1/obj.fs); 
                    ten = nan*ones(N_XT_CH, maxLen, N_TRIALS); 
                case {'Trim', 'trim'}
                    TRIM = 1; 
                    %// Trim signals to shortest trial
                    minTLen = min(obj.trTimeLen(useTrials)); 
                    minLen  = ceil(minTLen*obj.fs+1/obj.fs);  
                    ten = zeros(N_XT_CH, minLen, N_TRIALS); 
            end
            for tri = 1:N_TRIALS
                tr = useTrials(tri); 
                xtData = cellvcat({(obj.data{1,tr}(useChannels).(vars.DATAFIELD))});
                if (TRIM == 1)
                    tLast = minLen; 
                    xt = xt(1:minLen); 
                else
                    tLast = size(xtData,2); 
                end
                ten(:,1:tLast,tri) = xtData(:,1:tLast); 
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
        function plot(obj, useTrials, useChannels, OFFSET, DATAFIELD)
            arguments
                obj
                useTrials   double = 1:obj.nTrials; 
                useChannels double = 1:obj.nChannels;  
                OFFSET      double = []; 
                DATAFIELD   char   = obj.dataField; 
            end
           
            N_PLOT_TRIALS = length(useTrials); 
            N_PLOT_ROWS = length(useChannels); 
            if N_PLOT_TRIALS > 1
                dataCellArr = cellstructhcat(obj.data(1,useTrials), DATAFIELD); 
            else
                dataCellArr = {obj.data{1,useTrials}(:).(DATAFIELD)}'; 
            end
            dataArr = cellvcat(dataCellArr(useChannels,:)); 

            %// Estimate the ideal offset for co-plotting
            if isempty(OFFSET)      
                maxVal = max(max(abs(diff(dataArr,1)))); 
                offset = 0.5*maxVal; 
            else
                offset = OFFSET; 
            end

            figure; 
            
            for m = 1:N_PLOT_ROWS
                plot(dataArr(m,:)-(m-1)*offset); 
                hold on; 
            end
            ylabel(strcat("Channel Offset = ", num2str(offset))); 
            title("Co-Plotted X(t) Data")
            xticklabels(xticks/obj.fs); 
            xlabel("Time (S)");      
            if N_PLOT_ROWS > 1
                nameDist = -offset*(m-1):offset:0; 
                yticks(nameDist); 
                yticklabels(flip(obj.electrode(useChannels))); 
            end
        end
    end
                
end