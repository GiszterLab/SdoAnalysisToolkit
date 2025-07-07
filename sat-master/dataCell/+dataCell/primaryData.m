%% primaryData Class - OOP (V2)
%
% Primary Data Dependencies 
%
% Used a plugin- composite for public classes.
%
% primaryData is used for the classes which directly interact with data,
% ensuring good handling, interconversion, and sampling; 
%
% primaryData is composed in: 
%   - xtDataCell
%   - ppDataCell
%   - pxtDataCell

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

classdef primaryData < handle & matlab.mixin.Copyable 
    properties
        %// Added here as common utils. 
        data        = []; 
        metadata    = []; 
        trialMeta   = []; % Temp ... Maybe to include? 
        dataType    {mustBeMember(dataType, {'xtData', 'ppData', 'pxtData', 'None'})} = 'None'; 
        dataSource  = []; 
        dataField   = []; 
        trTimeStart = []; 
        trTimeStop  = []; 
        trTimeLen   = []; % Populate this during import; 
    end
    properties (Dependent) % public; 
        fs          {mustBeNonnegative}
        nTrials     {mustBeInteger}
        nChannels   {mustBeInteger}
        sensor        
    end
    
    properties (Hidden, Dependent)
        sampledData     {mustBeNumericOrLogical}
        validDataField  {mustBeNumericOrLogical}
        haveSensorNames {mustBeNumericOrLogical}
    end
    
    methods
        %% Dynamic/Dependent methods
        function LI = get.sampledData(obj)
            if isempty(obj.data)
                LI = false; 
                return
            end
            N_CHANNELS = size(obj.data{1,1},1); 
            LI = false; 
            %
            tr = 1; 
            while tr <= obj.nTrials
                m = 1; 
                while m <= N_CHANNELS
                    if ~isempty(obj.data{1,tr}(m).(obj.dataField))
                        LI = true; 
                        break
                    end
                    m = m+1; 
                end
                tr = tr+1; 
                if LI == true
                    break
                end
            end
        end
        %------------------------------%
        function LI = get.validDataField(obj)
            LI = ismember(obj.dataField, fieldnames(obj.data{1,1})); 
        end
        %------------------------------%
        function LI = get.haveSensorNames(obj)
            LI = ~isempty(obj.sensor); 
        end

        %------------------------------%
        function nTrials = get.nTrials(obj)
            if isempty(obj.data)
                nTrials = 0; 
            else
                nTrials = size(obj.data,2); 
            end
        end
        %------------------------------%
        function nChannels = get.nChannels(obj)
            if isempty(obj.data)
                nChannels = 0; 
            else
                nChannels = length(obj.data{1,1}); 
            end
        end
        %-----------------------------%
        function sensor = get.sensor(obj)
            if ~obj.sampledData
                sensor = {}; 
            else
                try
                    sensor = {obj.data{1,1}(:).sensor}; 
                catch
                    sensor = {}; 
                end
            end
        end
        %------------------------------------%
        function fs = get.fs(obj)
            if ~isempty(obj.data{1,1}(1).fs)
                fs = obj.data{1,1}(1).fs; 
            else
                fs = 0; 
            end
        end
        
        %% Constructor
        function obj = primaryData(dataClass, N_TRIALS, N_CHANNELS)
            switch dataClass
                case 'ppData'
                    S = dataCell.constructors.getPpDataHolder(N_TRIALS, N_CHANNELS); 
                case 'xtData'
                    S = dataCell.constructors.getXtDataHolder(N_TRIALS, N_CHANNELS); 
            end
            obj.data = S; 
        end
        
        %% import 
        function obj = import(obj, dataHolder, dataSource)
            arguments
                obj
                dataHolder cell
                dataSource = []; 
            end
            
            obj.data = dataHolder(1,:);
            if size(dataHolder,1) > 1
                % has metadata
                obj.metadata = dataHolder(2,:); 
            end
            obj.dataSource = dataSource;
            % TODO: Clean this up a bit; make trTimeLen dependent
            obj.trTimeStart = zeros(1, obj.nTrials); 
            obj.trTimeLen   = zeros(1, obj.nTrials); 
            obj.calc_trTimeLen; 
            obj.trTimeStop  = obj.trTimeStart + obj.trTimeLen; 
        end
        %%-------------Calc trTimeLen---------
        function obj = calc_trTimeLen(obj)
            for tr = 1:obj.nTrials
                mx_v = 0; 
                for ch = 1:obj.nChannels
                    if ~isempty(obj.data{1,tr}(ch).times)
                        mx_v = max(mx_v, obj.data{1,tr}(ch).times(end)); 
                    else
                        continue
                    end
                end
                obj.trTimeLen(tr) = mx_v; 
            end
        end
        %%-------------- Combine---------------
        function obj = combine(obj, obj2)
            arguments
                obj
                obj2 primaryData
            end
            if ~strcmp(obj.dataType, obj2.dataType)
                disp("Data fields are not the same");
                return
            end
            if ~(obj.nChannels == obj2.nChanngels)
                disp("nChannels is not identical"); 
                return
            end
            obj.data        = {obj.data, obj2.data}; 
            obj.metadata    = {obj.metadata, obj2.metadata}; 
            % Retain obj1's classification       
        end
        %% Data-Relevant Functions
        
        %_______ Reordering ________
        function obj = reorder(obj, trialOrder, channelOrder)
            arguments
               obj
               trialOrder = []; 
               channelOrder = []; 
            end
            if isempty(trialOrder)
                trialOrder = 1:obj.nTrials; 
            end
            if isempty(channelOrder)
                channelOrder = 1:obj.nChannels; 
            end
            % __ rearrange trials --> cols __ #
            obj.data(trialOrder); 
            for tr =1:obj.nTrials
                obj.data{1,tr} = obj.data{1,tr}(channelOrder); 
            end
        end
        %-----------------------------------------------------%
        function obj_out = subsample(obj, TRIAL_IDX, ROW_IDX)
            arguments
                obj
                TRIAL_IDX   {mustBeInteger}
                ROW_IDX     {mustBeInteger} 
            end
            if ~obj.sampledData
                obj_out = obj; 
                return
            end
            
            obj_out = copy(obj);
            N_USE_TR = length(TRIAL_IDX); 
            % ___ Strip
            obj_out.data        = obj_out.data(1,TRIAL_IDX); 
            obj_out.metadata    = obj_out.metadata(1,TRIAL_IDX);  
            obj_out.trTimeLen   = obj_out.trTimeLen(TRIAL_IDX); 
            for tr = 1:N_USE_TR
                %// Having already cut trials, now cut rows; 
                obj_out.data{1,tr} = obj_out.data{1,tr}(ROW_IDX); 
            end
        end
        %------------------------------------------------------
        function [obj_out] = getDataInRange(obj, tRange, useChannels, useTrials)
            arguments
               obj
               tRange (1,2) % [t0, t1]
               useChannels  = 1:obj.nChannels; 
               useTrials    = 1:obj.nTrials; 
            end
            nUseTrials      = length(useTrials); 
            nUseChannels    = length(useChannels); 
            obj_out = obj.copy(); 
            datCell = obj.data(1, useTrials); 
            for tr = 1:nUseTrials
                datCell{1,tr} = datCell{1,tr}(useChannnels); 
                for ch = 1:nUseChannels
                    switch obj.dataType
                        case 'ppData'
                            times = datCell{1,tr}(ch).times; 
                        case 'xtData'
                            times = obj.data{1,tr}(1).times; 
                    end
                    idx = (times>=tRange(1)) && (times<tRange(2));
                    % !! This is a bit fragile !!
                    switch obj.dataType
                        case 'ppData'
                            datCell{1,tr}(ch).times = times(idx); 
                            datCell{1,tr}(ch).nEvents = nnz(idx);
                        case 'xtData'
                            datCell{1,tr}(1).times = times(idx); 
                    end
                    datCell{1,tr}(ch).envelope = datCell{1,tr}(ch).envelope(idx); 
                end
            end
            obj_out.data = datCell; 
            % Idea here would be to subsample data within trials 
            obj_out.trTimeLen = tRange(2); 
        end
        
        %------------------------------------------------------
        % TODO: Disable this for PPDC(?)
        function obj = resample(obj, DESIRED_HZ, DATAFIELD) 
            arguments
                obj
                DESIRED_HZ double   = obj.fs; 
                DATAFIELD char      = obj.dataField; 
            end
            if ~strcmp(obj.dataType, 'xtData')
                disp("resample not yet defined for datatype"); 
                return
            end
            if ~obj.sampledData
                disp("No data to resample")
                return
            end
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
        %% Conversion Methods 
        % TODO: Expand; Perhaps breakout different 'data' with subclasses?
        function obj_out = convertDataType(obj, newDataType, vars)
            arguments
                obj
                newDataType {mustBeMember(newDataType, {'ppData', 'xtData'})}
                vars.fs         = obj.fs; 
                vars.rateCode   = 0; % non-destructive accumulation
            end
            obj_out = obj.copy; 
            switch obj.dataType
                case 'ppData'
                    switch newDataType
                        case 'xtData'
                            st = obj.getData(); 
                            for tr = 1 :obj.nTrials
                                binData = binarize_ppData(st(:,tr), vars.fs, obj.trTimeLen(tr), vars.rateCode); 
                                % -- 
                                for ch = 1:obj.nChannels
                                    obj_out.data{1,tr}(ch).times    = []; 
                                    obj_out.data{1,tr}(ch).raw      = binData(ch,:); 
                                    obj_out.data{1,tr}(ch).envelope = binData(ch,:); 
                                    obj_out.data{1,tr}(ch).fs       = vars.fs; 
                                end
                                obj_out.data{1,tr}(1).times = 0:1/vars.fs:obj.trTimeLen(tr)-1/vars.fs;
                            end
                            obj_out.dataType = 'xtData'; 
                            obj_out.dataField = 'envelope'; 
                    end
                    %--------------------------------------
            end
            
            
        end
        %--------------------- Utilities---------------------
        % -- > Takes a cell or string/char
        % --> Convert this into a mix-in?
        function CH_IDX = getChannelIndex(obj, NAME)
            [CH_IDX] = find(ismember(cellfun(@char, obj.sensor, ...
                'uniformOutput',0), cellfun(@char, NAME, 'uniformOutput',0))); 
        end
        
        %%
        % --------------------- vcat--------------------------
        % Old "merge" method; 
        % --> vertical concat in the context of datacell5
        % refers to adding more data to each trial
        % --> N_TRIALS must be the same, else dummied; 
        function obj = vcat(obj, obj2)
            arguments
                obj
                obj2 dataCell.primaryData
            end
            if ~(obj.nTrials == obj2.nTrials)
                disp("Data structures to combine have an unequal number of trials!")
                return
                % TODO: Handling of edge cases; 
            end
            if ~strcmp(obj.dataType, obj2.dataType)
                disp("Unlike data structures attempting to combine")
            end
            if ~(obj.fs == obj2.fs)
                obj2.resample(obj.fs); 
            end
            
            for tr = 1:obj.nTrials
                %
                if ~(obj.trTimeLen(tr) == obj2.trTimeLen(tr))
                    % TODO: Fix this with a padding/clipping method; 
                end
                obj.trTimeLen(tr) = max(obj.trTimeLen(tr), obj2.trTimeLen(tr)); 
                % This works will structures are [1xnChannels]
                obj.data{1,tr} = [obj.data{1,tr}, obj2.data{1,tr}]; 
            end
            try 
                obj.metadata = structmerge(obj.metadata, obj2.metadata); 
            catch
                for tr=1:obj.nTrials
                    % historical; 
                    obj.metadata{tr} = structmerge(obj.metadata{tr}, obj2.metadata{tr},2);
                end
            end
            obj.calc_trTimeLen; 
        end
        %-----------------------------hcat-------------------------------
        % use to add trials together; just need to scan for nChannels
        function obj = hcat(obj, obj2)
            arguments
                obj
                obj2
            end
            if ~ (obj.nChannels == obj2.nChannels)
                %TODO: 
                disp("Data objects have an incompatible number of channels");
                return
            end
            obj.data = [obj.data, obj2.data]; 
            obj.metadata = structmerge(obj.metadata, obj2.metadata, 1); 
            obj = calc_trTimeLen(obj); 
        end
        %------------------------------------------------------
        function values = getValuesAtIndices(obj, indices, vars)
            arguments
                obj
                indices = []; 
                vars.useChannels    = 1:obj.nChannels;
                vars.useTrials      = 1:obj.nTrials; 
                vars.dataField      = obj.dataField; 
            end            
     
            N_USE_TRIALS    = length(vars.useTrials); 
            N_USE_XT_CH     = length(vars.useChannels);
            
            % __ Pre-parse
            if ~iscell(indices)
                % Evaluate time points across ALL trials?? 
                indices = repelem({indices}, 1, N_USE_TRIALS);  
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
            
            % Ideally, we want to get the output as a {N_CHANNELS x N_TRIALS} cell of
            % lookup values 
            
            values = cell(N_USE_XT_CH, N_USE_TRIALS);
            for tri = 1:N_USE_TRIALS
                tr = vars.useTrials(tri); 
                if isempty(indices{tri})
                    continue
                end
                for chi = 1:N_USE_XT_CH
                    ch = vars.useChannels(chi); 
                    % __ Iterative Lookup
                    values{chi,tri} = obj.data{1,tr}(ch).(vars.dataField)(indices{tri}); 
                    if (size(indices{tri},1) >1) && (size(values{chi,tri},1) == 1)
                        % deal with transposed columns
                        values{chi,tri} = values{chi,tri}'; 
                    end
                end
            end
            
        end
        %------------------------------------------------------
        % ___>> Generic get method w/ optional concat; 
        function data = getData(obj, useTrials, useChannels, vars)
            arguments
                obj
                useTrials   {mustBeNumeric} = 1:obj.nTrials; 
                useChannels {mustBeNumeric} = 1:obj.nChannels; 
                vars.dataField              = obj.dataField; 
                vars.trialwise              = 1; % keep separate; 
                vars.channelwise            = 1; % keep separate; 
                vars.mergeMethod {mustBeMember(vars.mergeMethod, {'none', 'time', 'level', 'mean_level'})} = 'none';
            end
            
            N_USE_CHANNELS  = length(useChannels); 
            N_USE_TRIALS    = length(useTrials); 
            
            % shortcut; 
            if (vars.trialwise) == 0 && (strcmp(vars.mergeMethod, 'none'))
                dat = cellstructhcat(obj.data(1, useTrials), vars.dataField);
                if vars.channelwise == 0
                    data = cellvcat(dat(useChannels,:)); 
                    return
                else
                    dat = data(useChannels,:); 
                    return;
                end
            end
            % _______ Collect _______________
            tempCatCell = cell(N_USE_CHANNELS, N_USE_TRIALS); 
            for tri = 1:N_USE_TRIALS
                tr = useTrials(tri); 
                for chi = 1:N_USE_CHANNELS
                    ch = useChannels(chi); 
                    tempCatCell{chi,tri} = obj.data{1,tr}(ch).(vars.dataField); 
                end
            end
            %________ Operate ________________________
            offsets = zeros(N_USE_CHANNELS, N_USE_TRIALS); 
            
            switch vars.mergeMethod
                case 'time' %phase in time; 
                    for chi = 1:N_USE_CHANNELS
                        offsets(chi,:) = cumsum([0,obj.trTimeLen(1:end-1)]); 
                    end
                % --> WARNING; These levelings may have to be calculated
                % cumulatively... 
                case 'level'
                    for tri = 2:N_USE_TRIALS
                        for chi = 1:N_USE_CHANNELS
                            offsets(chi,tri) = tempCatCell{chi,tri}(1)-tempCatCell{chi,tri-1}(end); 
                        end
                    end
                case 'mean_level'
                    for tri = 2:N_USE_TRIALS
                        for chi = 1:N_USE_CHANNELS
                            offsets(chi,tri) = mean(tempCatCell{chi,tri})-mean(tempCatCell{chi,tri-1}); 
                        end
                    end
            end
            % // apply offsets; 
            for tri = 1:N_USE_TRIALS
                for chi = 1:N_USE_CHANNELS
                    tempCatCell{chi,tri} = tempCatCell{chi,tri}+offsets(chi,tri); 
                end
            end
            %
            if vars.trialwise == 0
                tempCatCell = cellhcat(tempCatCell); 
            end
            if vars.channelwise == 0
                tempCatCell = cellvcat(tempCatCell); 
            end
            data = tempCatCell; 
        end
        
        %------------------------------------------------------
        % This can stay here for now, but will probably want to migrate out
           function f = plot(obj, useTrials, useChannels, OFFSET, vars)
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
            if nargout > 0
                f = figure; 
            end
            
            DATAFIELD = vars.datafield; 
            N_PLOT_TRIALS = length(useTrials); 
            N_PLOT_ROWS = length(useChannels); 
            if ~isfield(obj.data{1,useTrials(1)}, DATAFIELD)
                disp(strcat(DATAFIELD, " is not a valid fieldname.")); 
            end
            
            if N_PLOT_TRIALS > 1
                dataCellArr = cellstructhcat(obj.data(1,useTrials), DATAFIELD); 
            else
                dataCellArr = {obj.data{1,useTrials}(:).(DATAFIELD)}'; 
            end

            dataArr = cellvcat(dataCellArr(useChannels,:)); 
            dataCell.plot_with_offset(dataArr, OFFSET); 
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
                if obj.haveSensorNames
                    yticklabels(flip(obj.sensor(useChannels))); 
                end
            end
          end
        %--------------------------------------------------------------%
        function obj = filter(obj, FILTERTYPE, N_POINTS, F_VAR, vars)
            arguments
                obj
                FILTERTYPE {mustBeMember(FILTERTYPE, {'notch', ...
                    'notchRMS', 'triRMSmov', 'trirmsmov','mov', ...
                    'gaussmov', 'trimov', 'expmov', ...
                    'rmsmov','bandpass', 'highpass', 'lowpass',...
                    'butter', 'emgButter'})}
                N_POINTS
                F_VAR = 1; %auxillary variable for ffilt
                vars.dataField = obj.dataField;
            end
            if ~obj.sampledData 
                disp("No Data sampled to filter."); 
                return
            end
            if ~ismember(obj.dataType, 'xtData')
                dis("Filtering for non-x(t) data is not yet defined"); 
                return
            end
            xtData = getTensor(obj, 'datafield', vars.dataField); 
            xtData2 = xtData; 
            for tr = 1:obj.nTrials 
                % --> upgraded callAfilter
                xt = squeeze(xtData(:,:,tr)); 
                fxt = callAfilter(xt,FILTERTYPE, obj.fs, 'nPoints', N_POINTS, 'auxVar', F_VAR); 
                xtData2(:,:,tr) = fxt(:,1:size(xt,2)); 
            end
            obj = obj.importTensor(xtData2, 'datafield', 'envelope'); 
        end       
           
        %%---------------------------- Get Tensor-------------------------
        function ten = getTensor(obj, useChannels, useTrials, vars)
            arguments
                obj
                useChannels         double = 1:obj.nChannels; 
                useTrials           double = 1:obj.nTrials; 
                vars.datafield      char = obj.dataField;
                vars.conform_method char {mustBeMember(vars.conform_method, {'pad', 'nanpad', 'trim'})} = 'pad'; 
                vars.averageDown = 1; % for multiple observations w/in trial
            end
            
            if ~obj.sampledData
                disp("No data sampled")
                ten = []; 
                return
            end

            N_TRIALS    = length(useTrials); 
            N_USE_CH    = length(useChannels);  

            % __ Slow Check
            nElem   = zeros(N_USE_CH, N_TRIALS); %obj.nTrials); 
            nChObs  = zeros(N_USE_CH,N_TRIALS); % for detecting stacks
            for tri = 1:N_TRIALS
                tr = useTrials(tri); 
                for chi = 1:N_USE_CH
                    ch = useChannels(chi);
                    [szY, szX, ~] = size(obj.data{1,tr}(ch).(vars.datafield)); 
                    nChObs(chi,tr) = szY; 
                    nElem(chi,tr) = max(szY, szX); 
                end
            end            
            
            %  Handle differences in X/ time
            switch vars.conform_method
                case {'Pad', 'pad'}
                    TRIM = 0; 
                    %// Zero Pad signals to maximum trial length; 
                    maxLen = max(nElem, [], 'all'); 
                    if vars.averageDown == 1
                        yMax = 1; 
                    else
                        yMax = max(nChObs, [], 'all'); 
                    end
                    ten = zeros(N_USE_CH, maxLen, N_TRIALS, yMax); 
                case {'nanpad'}
                    TRIM = 0; 
                    maxLen = max(nElem, [], 'all'); 
                    if vars.averageDown == 1
                        yMax = 1; 
                    else
                        yMax = max(nChObs, [], 'all'); 
                    end
                    ten = nan*ones(N_USE_CH, maxLen, N_TRIALS, yMax); 
                case {'Trim', 'trim'}
                    TRIM = 1; 
                    %// Trim signals to shortest trial
                    minLen = min(nElem(nElem>0), [], 'all'); 
                    if vars.averageDown == 1
                        yMax = 1; 
                    else
                        yMax = min(min(nChObs, [], 'all'),1); 
                    end                    
                    ten = zeros(N_USE_CH, minLen, N_TRIALS, yMax);  
            end

           % Handle differences in Y/ # Observations; 
            for tri = 1:N_TRIALS
                xtCell = {obj.data{1,tr}(useChannels).(vars.datafield)}; 
                %// single obs; default; 
                if (yMax < 2) && any(nChObs(:,tr)>1)
                    % // average down; 
                    xtData = cellvcat( cellfun(@mean, xtCell, repelem({1},1,N_USE_CH), 'UniformOutput', false)' ); 
                elseif (yMax < 2)
                    %// pass; 
                    xtData = cellvcat(xtCell'); 
                else
                    %// retain sample depth; 
                    % -->> NOTE: this will break if there is an unequal
                    % number of obs per channel; 
                    xtData = cellzcat(xtCell'); 
                    xtData = permute(xtData, [3,2,1]); %[Channel; xt; event]
                end

                %xtData = cellvcat({(obj.data{1,tr}(useChannels).(vars.DATAFIELD))});
                if isempty(xtData)
                    continue; 
                end
               [~,~, szZ] = size(xtData); 

                if (TRIM == 1)
                    tLast = minLen; 
                    xtData = xtData(:,1:minLen,:); 
                else
                    tLast = size(xtData,2); 
                end
                if szZ > 1
                    ten(:,1:tLast,tri,1:szZ) = xtData(:,1:tLast,:); 
                else
                    ten(:,1:tLast,tri,1)     = xtData(:,1:tLast); 
                end
            end                  
        end         
        
        %--------------- Import Tensor----------------------------------%
        function obj_out = importTensor(obj, ten, vars)
            % Repopulate data using supplied 2-3D Tensor; 
            % For the core method, we'll make the assumption that the
            % tensor is already fully formed. 
            %
            % TODO: Optimization: This code is a bit hard to maintain
            arguments
                obj 
                ten double
                vars.useChannels    {mustBeInteger} = 1:obj.nChannels; 
                vars.useTrials      {mustBeInteger} = 1:obj.nTrials; 
                vars.datafield      char = obj.dataField;
            end
                
            obj_out = copy(obj); 
           
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
                    obj_out.data{1,tr}(ch).(vars.datafield) = xt(1:xtLen); 
                    % -->> Regenerate min/max; 
                end
            end
        end
        %--------------------------------------------------------------%
        function obj= validateData(obj)
            switch obj.dataType
                case 'None'
                    return
                case 'xtData'
                    1; 
                case 'ppData'
                    obj.validate_primaryData_ppdata; 
            end
            
            
        end
        
        
        
    end
    
    %% PRIVATE METHODS
    methods (Hidden)
        function obj = validate_primaryData_ppdata(obj)
            if ~obj.sampledData
                return; 
            end
            for tr = 1:obj.nTrials
                for u =1:obj.nChannels
                    % Horizontal Time row vectors; 
                    % (Maybe one day we can flip this to cols...)
                    if ~isempty(obj.data{1,tr}(u).times)
                        [sz_y,sz_x] = size(obj.data{1,tr}(u).times);  
                        if (sz_y > sz_x) && (sz_y > 1)
                            obj.data{1,tr}(u).times = obj.data{1,tr}(u).times'; 
                        end
                    end
                    % Horizontal Envelopes
                    if ~isempty(obj.data{1,tr}(u).envelope)
                        [sz_y,sz_x] = size(obj.data{1,tr}(u).envelope);
                        if (sz_x == obj.data{1,tr}(u).nEvents) && ~(sz_x == sz_y)
                            % This is set as col vects; 
                            obj.data{1,tr}(u).envelope = obj.data{1,tr}(u).envelope'; 
                        end
                    else
                        if obj.data{1,tr}(u).nEvents > 0
                            %// Dummy with blank; 
                            obj.data{1,tr}(u).envelope = ones(obj.data{1,tr}(u).nEvents, 2); 
                        end
                    end
                    %{
                    % --> Could insert validate shuffles; 
                    if obj.shuffledSpikes 
                        if obj.data{1,tr}(u).nEvents > 0
                            [sz_y, sz_x] = size(obj.data{1,tr}(u).shuffle); 
                            % Check that these are horizontal; 
                            if ~(sz_x == obj.data{1,tr}(u).nEvents) && (sz_y > 1)
                                obj.data{1,tr}(u).shuffle = obj.data{1,tr}(u).shuffle'; 
                            end
                        end
                    end
                    %}
                end
            end
        
        end
        %-----------------------------------------------------------------------------------%
    end
end