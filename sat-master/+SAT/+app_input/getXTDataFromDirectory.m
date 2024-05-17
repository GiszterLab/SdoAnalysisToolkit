% Description:  Get XT data from a directory 
% Parameter:    None
% Return Value: xt_cell - Nx2 cell array where the {1,1} contains the header
%                         and the second column contains xt matrix data for 
%                         each trial
% Note:         The directory must contain only the 

function xt_cell = getXTDataFromDirectory ()
    % Get XT Files from directory
     try xt_files = SAT.app_input.helper.getFiles();
     catch 
         return
     end

    % Initialize the cell
    xt_cell = cell(length(xt_files), 2);

    for i = 1 : length(xt_files) 
        if i == 1
        opts = detectImportOptions(xt_files{i});
        old_header_cell = opts.VariableNames;
        end

        % Check if all the headers for XT Files are the same
        if i > 1 
            opts = detectImportOptions(xt_files{i});
            current_header_cell = opts.VariableNames;
            if ~SAT.app_input.helper.checkColumns(old_header_cell, current_header_cell)
                error_msg = sprintf("!!!You don't have the same header at!!!");
                error(error_msg);
            end
            old_header_cell = current_header_cell;
        end

        % Insert the XT data
        xt_cell{i,2} = readmatrix(xt_files{i});

        % At the last loop, after checking headers have matched, insert
        if i == length(xt_files)
            xt_cell{1,1} = old_header_cell;
        end
    end
end