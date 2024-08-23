% Description:  Create an XT data cell object for SMM
% Parameters:   xt_cell - Nx2 cell where N is trials
%                         The headers are at {1,1} position
%                         The 2nd column has all the xt data
%               sampleR - Sampling Rate for EMG
% Return Value: xtdc - xtDataCell object

function xtdc = fillXTDC(xt_cell, sampleR)
    arguments
        xt_cell (:,2) cell
        sampleR (1,1) double {mustBeNonnegative}
    end

    % Initialize xtDataHolder object
    xt_data_holder = SAT.xtDataHolder_new(height(xt_cell), width(xt_cell{1,2}));
    
    % Loop through each trial
    for i = 1 : width(xt_data_holder)
        % Loop through each emg channel
        for j = 1 : length(xt_data_holder{1,i})
    
            % Insert raw data
            xt_data_holder{1,i}(j).raw = xt_cell{i,2}(:,j)'; % column data required
            % Insert envelope data
            xt_data_holder{1,i}(j).envelope = xt_cell{i,2}(:,j)'; % column data required
    
            % Insert sensor's name
            xt_data_holder{1,i}(j).sensor = xt_cell{1,1}{j};

            % Insert frequency
            xt_data_holder{1,i}(j).fs = sampleR; 
        end
        
        % Insert times
        xt_data_holder{1,i}(1).times = (0 : 1/sampleR : (1/sampleR) * (height(xt_cell{i,2})-1))'; % row data required
    end

    % After filling the holder, initialize xt data cell and insert it
    xtdc = xtDataCell(width(xt_data_holder), length(xt_data_holder{1,1}));
    xtdc.import(xt_data_holder);
end