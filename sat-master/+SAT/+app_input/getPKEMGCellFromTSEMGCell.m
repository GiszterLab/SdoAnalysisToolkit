% Name: Phone Kyaw
% Date: 09/10/2024

function [pk_xt_cell, xtdc] = getPKEMGCellFromTSEMGCell()
% Description:   Get Phone's xt_cell for the app from Trevor's xt_cell
% Parameters:    None
% Return Values: pk_xt_cell - Phone's xt_cell
%                xtdc - xtDataCell

arguments(Output)
    pk_xt_cell (:,2) cell
    xtdc xtDataCell
end
   
    % Get the filepath for '.mat' file
    [file_name, path] = uigetfile({'*.mat', '.mat Files'}, 'MultiSelect','off');
    file_path = fullfile(path, file_name);
    
    % If the user inputted nothing
    if file_name == 0
        pk_xt_cell = {};
        xtdc = xtDataCell();
        return
    end

    % We only want one variable inside the '.mat' file
    if length(whos('-file', file_path)) > 1
        error('There is more than one file')
    end
    
    % Get Trevor's xt_cell and import it insdie xtDataCell
    ts_xt_cell = load(file_path);
    field_name = fieldnames(ts_xt_cell);
    ts_xt_cell = ts_xt_cell.(field_name{1});
    xtdc = xtDataCell();
    xtdc.import(ts_xt_cell);
    
    % Initialize PK xt_cell
    pk_xt_cell = cell(length(ts_xt_cell), 2);
    
    for i = 1 : length(ts_xt_cell)
        % Get raw data
        tensor = xtdc.getTensor(1:xtdc.nChannels, i, 'DATAFIELD', 'raw')';
        pk_xt_cell{i,2} = tensor;
    end

    % Get the channels' name and sampling rate
    pk_xt_cell{1,1} = xtdc.sensor;
end