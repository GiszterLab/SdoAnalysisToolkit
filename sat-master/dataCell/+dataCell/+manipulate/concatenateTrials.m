
%
% Trial-concatenation across the datasets. Allows for trials to be combined
% together; Handled at the level of xtDataCell and ppDataCell; 

function obj = concatenateTrials(obj, useTrials)
    arguments
        obj
        useTrials = 1:obj.nTrials; 
    end

    % Concatenate data from given trials; 

    % Combine data accordingly

    nUseTrials = length(useTrials); 
    %
    dT = diff(useTrials); 
    % // we can only combine adjacent trials. 

    if max(dT) > 1
        disp("Only adjacent trials can be concatenated"); 
        return
    end
    %

    nNewTrials = obj.nTrials - nUseTrials + 1; % After cat, expected size; 

    newIDX = min(useTrials); % cat down; 

    % __ Need to generate an index here; 

    %// assuming we are cating only a single element, there are three
    %components; 
    preIDX = 1:newIDX-1; 
    posIDX = (newIDX+nUseTrials:obj.nTrials); 

    lkupIDX =  [preIDX, repmat(newIDX, 1, nUseTrials), posIDX-nUseTrials];

    % -->> The amount of fields which need to be populated and checked
    % adhoc; require a switch-case, unfortuately 
   
    type = class(obj); 
    switch type
        %=================================================================
        case 'xtDataCell'
            %_______________
            miniData = obj.data(:,useTrials); 
            sFields = {...
                'envelope', ...'
                'raw', ...
                'offset', ... 
                'stateSignal', ...
                'signalLevels'}; 
            
            miniStruct = dataCell.constructors.getXtDataHolder(1, obj.nChannels); % Dummy Empty; 
            for f = 1:length(sFields)
                %if ~isempty(

                dat = cellstructhcat(miniData, sFields{f});
                if isempty(dat); continue; end
                for ch = 1:obj.nChannels
                    miniStruct{1,1}(ch).(sFields{f}) = dat{ch}; 
                end
            end
            % 
            % // Post-populate with single fields
            sFields2 = {'sensor', 'fs'}; 
            for f = 1:length(sFields2)
                for ch = 1:obj.nChannels
                    miniStruct{1,1}(ch).(sFields2{f}) = obj.data{1,newIDX}(ch).(sFields2{f}); 
                end
            end

            %// Now we have to re-cat the times; 
            t0 = obj.data{1,newIDX}(1).times(1); %Usually 0; 
            tPts = length(miniStruct{1,1}(1).envelope); % Hard code
            hz = miniStruct{1,1}(1).fs; 
            tMax = t0+(tPts-1)/hz; 
            tVect = t0:1/hz:tMax; % Time Vector; 
            %
            miniStruct{1,1}(1).times = tVect; 
            %_______________________
            dataH = dataCell.constructors.getXtDataHolder(nNewTrials, obj.nChannels); 
            obj2 = xtDataCell; 
            obj2.copyProperties(obj, ...
                {'dataSource', ...
                'mapMethod', ... 
                'maxMode', ... 
                'nBins', ... 
                'weightMatrix', ... 
                'nActivationsUsed', ...
                'decomposeMethod'}); 
            
        %=================================================================
        case 'ppDataCell'
            %_______________________
            miniData = obj.data(:,useTrials); 
            sFields = {'envelope', 'shuffle'}; 

            miniStruct = dataCell.constructors.getPpDataHolder(1, obj.nChannels); % Dummy Empty; 
            for f = 1:length(sFields) 
                for ch = 1:obj.nChannels
                    tmpCell = cell(nUseTrials,1); 
                    for tr = 1:nUseTrials
                        tmpCell{tr,1} = miniData{1,tr}(ch).(sFields{f}); % copy; 
                    end
                    miniStruct{1,1}(ch).(sFields{f}) = cellvcat(tmpCell); 
                end
            end

            % // for times we MUST assume some sort of maximal value; Take
            % this from the amplitude prepopulated parameters; 

            % 
            % // Post-populate with single fields
            sFields2 = {'sensor', 'fs'}; 
            for f = 1:length(sFields2)
                for ch = 1:obj.nChannels
                    miniStruct{1,1}(ch).(sFields2{f}) = obj.data{1,newIDX}(ch).(sFields2{f}); 
                end
            end
            %
            % __ Summation; 
            for ch = 1:obj.nChannels
                miniStruct{1,1}(ch).nEvents = length(miniStruct{1,1}(ch).times); 
            end

            tDiff = obj.trTimeLen(lkupIDX); % Load offsets; 

            tOff = [0 cumsum(tDiff(1:end-1))]; 

            for ch = 1:obj.nChannels
                stCell = cell(1,nUseTrials); 
                for tr = 1:nUseTrials             
                    % Adjust times based by onsets; 
                    stCell{1,tr} = miniData{1,tr}(ch).times + tOff(tr); 
                end
                miniStruct{1,1}(ch).times = cellhcat(stCell); 
            end
            %___________________
            dataH = dataCell.constructors.getPpDataHolder(nNewTrials, obj.nChannels); 
            obj2 = ppDataCell; 
    end

    if ~isempty(preIDX)
        dataH(1,preIDX) = obj.data(1,preIDX); %copy; 
        dataH(2,preIDX) = obj.metadata(1,preIDX); %copy; 
    end
    dataH{1,newIDX} = miniStruct{1,1}; 
    dataH{2,newIDX} = obj.metadata(1, newIDX); 
    if ~isempty(posIDX)
        dataH(1,newIDX+1:end) = obj.data(1,posIDX); 
        dataH(2,newIDX+1:end) = obj.metadata(1,posIDX); 
    end
    
    obj2.import(dataH); 
    
    obj = obj2; 
   

    1; 



end