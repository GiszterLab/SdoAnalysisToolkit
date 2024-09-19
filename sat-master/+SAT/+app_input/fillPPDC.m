% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Return a PP data cell object for SMM
% Parameters:   pp_cell - Nx1 cell where N is a trial. Inside each
%               cell is a Mx2 cell where M is sensor and the second column
%               is the activation time
%               frequency - sampling rate
% Return Value: ppdc - ppDataCell object

function ppdc = fillPPDC (pp_cell, frequency)
arguments
    pp_cell (:,1) cell
    frequency (1,1) double {mustBePositive} = 30000
end
    % Initialize PP data holder object
    pp_data_holder = SAT.ppDataHolder_new(height(pp_cell), height(pp_cell{1}));
    
    for i = 1 : height(pp_cell)
        for j = 1 : height(pp_cell{i})
            % Fill in all the pp values
            pp_data_holder{1,i}(j).sensor = pp_cell{i}{j,1};
            pp_data_holder{1,i}(j).times = pp_cell{i}{j,2};
            pp_data_holder{1,i}(j).envelope = pp_cell{i}{j,2};
            pp_data_holder{1,i}(j).nEvents = width(pp_cell{i}{j,2});
            pp_data_holder{1,i}(j).fs = frequency;
        end
    end

    % After filling the holder, initialize pp data cell and insert it
    ppdc = ppDataCell(width(pp_data_holder), length(pp_data_holder{1,1}));
    ppdc.import(pp_data_holder);
end