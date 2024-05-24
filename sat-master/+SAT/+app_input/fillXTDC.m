% Description:  Create an XT data cell object for SMM
% Parameters:   xt_cell - Nx2 cell where N is trials
%                         The headers are at {1,1} position
%                         The 2nd column has all the xt data
%               times -   Times data for xtDataCell
% Return Value: xtdc - xtDataCell object

function xtdc = fillXTDC(xt_cell, times)
    arguments
        xt_cell (:,2) cell
        times (1,:) double {mustBeNonnegative}
    end

    % Initialize xtDataHolder object
    xt_data_holder = SAT.xtDataHolder_new(height(xt_cell), width(xt_cell{1,2}));
    % Calculate frequency
    frequency = 1 / (times(2)-times(1));
    
    for i = 1 : width(xt_data_holder)
        for j = 1 : length(xt_data_holder{1,i})
    
            % Insert raw data
            xt_data_holder{1,i}(j).raw = xt_cell{i,2}(:,j)'; % row data required
            % Insert envelope data
            xt_data_holder{1,i}(j).envelope = xt_cell{i,2}(:,j)'; % row data required
    
            % Insert sensor's name
            xt_data_holder{1,i}(j).sensor = xt_cell{1,1}{j};

            % Insert frequency
            xt_data_holder{1,i}(j).fs = frequency; 
        end
        
        % Insert times
        xt_data_holder{1,i}(1).times = times;
    end

    % After filling the holder, initialize xt data cell and insert it
    xtdc = xtDataCell(width(xt_data_holder), length(xt_data_holder{1,1}));
    xtdc.import(xt_data_holder);
end