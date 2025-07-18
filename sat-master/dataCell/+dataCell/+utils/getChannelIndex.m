function CH_IDX = getChannelIndex(obj, NAME)
[CH_IDX] = find(ismember(cellfun(@char, obj.sensor, ...
    'uniformOutput',0), cellfun(@char, NAME, 'uniformOutput',0))); 
end