
%% Generate the pxtDataCell from sdoMat/sdoMultiMat with appropriate parameters; 
function pxtdc = getConformedPxtDataCell(obj, type)
arguments
    obj 
    type {mustBeMember(type, {'px0', 'px1'})} = 'px0'; 
end
    pxtdc = pxtDataCell; 
  
    if ~isempty(obj.pxProperties)
        pxtdc.zDelay    = obj.pxProperties.zDelay; 
        pxtdc.nShift    = obj.pxProperties.nShift; 
        pxtdc.filterWid = obj.pxProperties.smoothingFilterWidth; 
        pxtdc.filterStd = obj.pxProperties.smoothingFilterStd; 
        switch type
            case 'px0'
                pxtdc.duraMs = obj.pxProperties.px0DurationMs; 
                %pxtdc.duraMs = abs(obj.pxProperties.px0DurationMs); 
            case 'px1'
                pxtdc.duraMs = obj.pxProperties.px1DurationMs; 
        end
    else
        %// Adhoc, less preferable
        pxtdc.copyProperties(obj, ...
            {'zDelay', 'nShift', 'filterWid', 'filterStd'}); 
        switch type
            case 'px0'
                pxtdc.duraMs = obj.px0DuraMs;  
                %pxtdc.duraMs = abs(obj.px0DuraMs); 
            case 'px1'
                pxtdc.duraMs = obj.px1DuraMs; 
        end

    end

end