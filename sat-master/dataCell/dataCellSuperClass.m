%% dataCellSuperClass
%
% || -- Superclass for generic methods of working w/ dataCell classes

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
            obj_out.sensor      = obj_out.sensor{ROW_IDX}; 
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
    
        %// copy matching datafields/fieldnames from dc into obj; 
        % --> Requires the target and link to have the same fieldnames;
        % Essentially a limited copy; 
        function obj = copyDataFields(obj, dc, getDataFields)
            %// modified clone of 'copyProperties'
            arguments
                obj
                dc
                getDataFields = []; 
            end
            if isempty(getDataFields)
                fn1 = fieldnames(obj.data{1,1}); 
                fn2 = fieldnames(dc.data{1,1}); 
                getDataFields = intersect(fn1, fn2); 
            end
            if ~isa(getDataFields, 'cell')
                getDataFields = {getDataFields}; 
            end
            N_FIELDS = length(getDataFields); 
            N_TRIAL_ROWS = length(obj.data{1,1}); 
            for tr = 1:obj.nTrials
                for row = 1:N_TRIAL_ROWS
                    for ff = 1:N_FIELDS
                        obj.data{1,tr}(row).(getDataFields{ff}) = dc.data{1,tr}(row).(getDataFields{ff}); 
                    end
                end
            end
        end

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
                    maxLen = max(nElem, [], 'all'); 
                    ten = zeros(N_USE_CH, maxLen, N_TRIALS); 
                case {'nanpad'}
                    TRIM = 0; 
                    maxLen = max(nElem, [], 'all'); 
                    ten = nan*ones(N_USE_CH, maxLen, N_TRIALS); 
                case {'Trim', 'trim'}
                    TRIM = 1; 
                    %// Trim signals to shortest trial
                    minLen = min(nElem(nElem>0), [], 'all'); 
                    ten = zeros(N_USE_CH, minLen, N_TRIALS); 
            end

            for tri = 1:N_TRIALS
                tr = useTrials(tri); 
                xtData = cellvcat({(obj.data{1,tr}(useChannels).(vars.DATAFIELD))});
                if isempty(xtData)
                    continue; 
                end
                if (TRIM == 1)
                    tLast = minLen; 
                    xtData = xtData(1:minLen); 
                else
                    tLast = size(xtData,2); 
                end
                ten(:,1:tLast,tri) = xtData(:,1:tLast); 
            end                  
        end
        %___ 
    end
    methods (Static)
        %// for stability reasons, this methods should be concretely implemented
        % separately in inheriting classes
        function [dataCellOut] = cloneDataRow(dataCell, SROW_IDX, N_CLONES)
            arguments
                dataCell
                SROW_IDX {mustBeInteger} = 1:length(dataCell{1,1}); 
                N_CLONES {mustBeInteger} = 1; 
            end
            dataCellOut = cell(size(dataCell)); 
            N_SROWS = length(SROW_IDX); 
            N_TRIALS = size(dataCell,2); 
            for tr = 1:N_TRIALS
                S = []; 
                for r=1:N_SROWS
                    if any(r == SROW_IDX)
                        S = [S repelem(dataCell{1,tr}(r), N_CLONES)]; 
                    else
                        S = [S dataCell{1,tr}(r)]; 
                    end
                end
                dataCellOut{1,tr} = S; 
                % __ 
            end
        end
        %__________________
    end

end