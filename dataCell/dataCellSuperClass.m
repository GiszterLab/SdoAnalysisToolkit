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
            obj_out.electrode   = obj_out.electrode{ROW_IDX}; 
            obj_out.trTimeLen   = obj_out.trTimeLen(TRIAL_IDX); 
            obj_out.nTrials     = N_USE_TR; 
            obj_out.nChannels   = N_USE_CH; 
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
end