%% Work in Progress


% Initialize xtDataHolder object
xt_data_holder = SAT.xtDataHolder_new(length(char_index), width(a));
for i = 1 : width(xt_data_holder)
    for j = 1 : length(xt_data_holder{1,i})
        % Insert raw data
        xt_data_holder{1,i}(j).raw = xt_cell{i}(:,j);
    end
end