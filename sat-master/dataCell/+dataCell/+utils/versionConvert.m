%% versionConvert
% Support script for handling upgrade/downgrades between older and better
% methods; 

function obj_out = versionConvert(obj, VERSION)
    arguments
        obj
        VERSION % INTEGER
    end
    
    CLASS_TYPE = class(obj); 
    switch CLASS_TYPE
        %===================================
        case {'xtDataCell', 'xtDataCell2'}
            sfields1 = {'channelAmpMax', 'channelAmpMin', 'mapMethod', 'maxMode'}; 
            sfields2 = {'weightMatrix', 'nActivationsUsed', 'decomposeMethod', 'nChannels'};
            %
            if isa(obj , 'xtDataCell')
                if (VERSION == 1)
                    obj_out = obj; 
                    return
                elseif (VERSION == 2) % v.1 --> v.2
                    obj_out = xtDataCell2(obj.nTrials, obj.nChannels); 
                    obj_out.import([obj.data; obj.metadata]); 
                    for f = 1:length(sfields1)
                        try
                            obj_out.stateMap.(sfields1{f}) = obj.(sfields1{f}); 
                        catch
                        end
                    end
                    for f = 1:length(sfields2)
                        try
                            obj_out.linearTransform(sfields2{f}) = obj.(sfields2{f}); 
                        catch
                        end
                    end
                end
            %----- 
            elseif isa(obj, 'xtDataCell2')
                if (VERSION == 2)
                    obj_out = obj; 
                    return
                elseif (VERSION == 1) % v.1 --> v2.
                    obj_out = xtDataCell(obj.nTrials, obj.nChannels); 
                    obj_out.import([obj.data.data; obj.data.metadata]); 
                    for f = 1:length(sfields1)
                        try
                            obj_out.(sfields1{f}) = obj.stateMap.(sfields1{f});  
                        catch
                        end
                    end
                    for f = 1:length(sfields2)
                        try
                            obj_out.(sfields2{f}) = obj_out.linearTransform(sfields2{f});
                        catch
                        end
                    end
                end
            end
            %===============================================
        case {'ppDataCell', 'ppDataCell2'}
            sfields = {'nShuffles', 'shuffMethod', 'shuffTau', 'shuffCIF'}; 
            if isa(obj, 'ppDataCell')
                if (VERSION == 1)
                    obj_out = obj;
                    return
                elseif (VERSION == 2) % v.1 --> v.2
                    obj_out = ppDataCell2(obj.nTrials, obj.nChannels);
                    obj_out.import([obj.data; obj.metadata]); 
                    for f = 1:length(sfields)
                        try
                            obj_out.shuffler.(sfields{f}) = obj.(sfields{f});
                        catch
                        end
                    end
                end
            elseif isa(obj, 'ppDataCell2')
                if (VERSION == 2)
                    obj_out = obj; 
                    return
                elseif (VERSION == 1) % v.2 --> v.1
                    obj_out = ppDataCell(obj.nTrials, obj.nChannels); 
                    obj_out.import([obj.data.data; obj.data.metdata]); 
                    for f = 1:length(sfields)
                        try
                            obj_out.(sfields{f}) = obj.shuffler.(sfields{f}); 
                        catch
                        end
                    end
                end
            end
    %============================================
    end      
           
end