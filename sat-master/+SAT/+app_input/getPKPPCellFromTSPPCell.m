% Name: Phone Kyaw
% Date: 09/10/2024

function [pk_pp_cell, ppdc] = getPKPPCellFromTSPPCell()
% Description:   Get Phone's pp_cell for the app from Trevor's pp_cell
% Parameters:    None
% Return Values: pk_pp_cell - Phone's pp_cell
%                ppdc - ppDataCell
arguments(Output)
    pk_pp_cell
    ppdc
end

    % Get the filepath for '.mat' file
    [file_name, path] = uigetfile({'*.mat', '.mat Files'}, 'MultiSelect','off');
    file_path = fullfile(path, file_name);

    % We only want one variable inside the '.mat' file
    if length(whos('-file', file_path)) > 1
        error('There is more than one file')
    end
    
    % Get Trevor's pp_cell and import it insdie ppDataCell
    ts_pp_cell = load(file_path);
    field_name = fieldnames(ts_pp_cell);
    ts_pp_cell = ts_pp_cell.(field_name{1});

    ppdc = ppDataCell();
    ppdc.import(ts_pp_cell);
    
    % Initialize PK pp_cell
    pk_pp_cell = cell(ppdc.nTrials, 1);
    
    for i = 1 : length(pk_pp_cell)
        pk_pp_cell{i} = cell(ppdc.nChannels, 2);
    
        for j = 1 : height(pk_pp_cell{i})
            pk_pp_cell{i}{j,1} = ts_pp_cell{1,i}(j).sensor; 
            pk_pp_cell{i}{j,2} = ts_pp_cell{1,i}(j).times;
        end
    end
end