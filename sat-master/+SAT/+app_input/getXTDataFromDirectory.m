% Description:  Get XT data from multiple XT files 
% Parameter:    xt_files - A cell array containing files' path
% Return Value: xt_cell - Nx2 cell array where the {1,1} contains the header
%                         and the second column contains xt matrix data for 
%                         each trial

function xt_cell = getXTDataFromDirectory (xt_files)
arguments
    xt_files (1,:) cell 
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
                error_file = split(xt_files{i},'\');
                error("!!!You don't have the same header at %s!!!", error_file{end});
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