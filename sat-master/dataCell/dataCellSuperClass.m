%% dataCellSuperClass
%
% || -- Superclass for generic methods of working w/ dataCells

classdef dataCellSuperClass < handle
    % _____ General Utils
    methods
        % ++ subsample Smaller variant
        function obj_out = subsample(obj, TRIAL_IDX, ROW_IDX)
            arguments
                obj
                TRIAL_IDX   {mustBeInteger}
                ROW_IDX     {mustBeInteger} 
            end
            obj_out = copy(obj);
            N_USE_TR = length(TRIAL_IDX); 
            N_USE_CH = length(ROW_IDX); 
            % ___ Strip
            obj_out.data        = obj_out.data(1,TRIAL_IDX); 
            obj_out.metadata    = obj_out.metadata(1,N_USE_TR); 
            obj_out.sensor   = obj_out.sensor{ROW_IDX}; 
            obj_out.trTimeLen   = obj_out.trTimeLen(TRIAL_IDX); 
            obj_out.nTrials     = N_USE_TR; 
            try
                obj_out.nChannels   = N_USE_CH;
            end
            for tr = 1:N_USE_TR
                %// Having already cut trials, now cut rows; 
                obj_out.data{1,tr} = obj_out.data{1,tr}(ROW_IDX); 
            end
        end
        %// copy matching properties from dc into obj
        function obj = copyProperties(obj, dc, getFields)
           arguments
               obj
               dc
               getFields = []; 
           end
            if isempty(getFields)
                fn1 = fieldnames(obj); 
                fn2 = fieldnames(dc); 
                fields = intersect(fn1,fn2); 
                getFields = setdiff(fields, 'data'); 
            end
            if ~isa(getFields, 'cell')
                getFields = {getFields}; 
            end
            N_FIELDS = length(getFields);
            for ff = 1:N_FIELDS
                obj.(getFields{ff}) = dc.(getFields{ff}); 
            end
        end
            %___ HOMOGENOUS DATA TRIM
        % --> Used to ensure from all trials are the same size; 
        % __ DISCRETIZE (Pre-Req for Pxt-mapping)
    end
    %____ Methods (Shared by some classes)
    methods (Hidden = true)
        %// somewhat clumsy way to set function only to some datacell
        %classes; quasi-abstract
        function ten = getTensor(obj, useChannels, useTrials, vars)
            arguments
                obj
                useChannels         double = 1:obj.nChannels; 
                useTrials           double = 1:obj.nTrials; 
                vars.DATAFIELD      char = obj.dataField;
                vars.CONFORM_METHOD char {mustBeMember(vars.CONFORM_METHOD, {'pad', 'nanpad', 'trim'})} = 'pad'; 
            end

            N_TRIALS    = length(useTrials); 
            N_USE_CH    = length(useChannels);  

            % __ Slow Check
            nElem = zeros(N_USE_CH, obj.nTrials); 
            for tri = 1:N_TRIALS
                tr = useTrials(tri); 
                for chi = 1:N_USE_CH
                    ch = useChannels(chi);
                    [szY, szX] = size(obj.data{1,tr}(ch).(vars.DATAFIELD)); 
                    nElem(chi,tr) = max(szY, szX); 
                end
            end            
            
            switch vars.CONFORM_METHOD
                case {'Pad', 'pad'}
                    TRIM = 0; 
                    %// Zero Pad signals to maximum trial length; 
                    %maxTLen = max(obj.trTimeLen(useTrials)); 
                    %maxLen = ceil(maxTLen*obj.fs+1/obj.fs); 
                    maxLen = max(nElem, [], 'all'); 
                    ten = zeros(N_USE_CH, maxLen, N_TRIALS); 
                case {'nanpad'}
                    TRIM = 0; 
                    %maxTLen = max(obj.trTimeLen(useTrials)); 
                    %maxLen = ceil(maxTLen*obj.fs+1/obj.fs); 
                    maxLen = max(nElem, [], 'all'); 
                    ten = nan*ones(N_USE_CH, maxLen, N_TRIALS); 
                case {'Trim', 'trim'}
                    TRIM = 1; 
                    %// Trim signals to shortest trial
                    %minTLen = min(obj.trTimeLen(useTrials)); 
                    %minLen  = ceil(minTLen*obj.fs+1/obj.fs);  
                    minLen = min(nElem(nElem>0), [], 'all'); 
                    ten = zeros(N_USE_CH, minLen, N_TRIALS); 
            end
            %}

            for tri = 1:N_TRIALS
                tr = useTrials(tri); 
                xtData = cellvcat({(obj.data{1,tr}(useChannels).(vars.DATAFIELD))});
                if isempty(xtData)
                    continue; 
                end
                if (TRIM == 1)
                    tLast = minLen; 
                    xt = xt(1:minLen); 
                else
                    tLast = size(xtData,2); 
                end
                ten(:,1:tLast,tri) = xtData(:,1:tLast); 
            end                  
        end
        %___ 
    end

end