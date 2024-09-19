% Name:         Phone Kyaw
% Date:         09/19/2024
% Description:  Return the XT header after stripping the XT data until
%               the cut parameter and finding the header in the stripped
%               data
% Parameters:   xt_data - Cell data that is read from file 
%               cut - The number of first rows
% Return Value: header - XT header as cell
% Use:          For concatenated XT file

function header =  getXTHeader(xt_data, cut)
arguments
    xt_data (:,:) cell
    cut (1,1) double {mustBeInteger, mustBePositive} = 3
end

    % Cut the cell
    cell_array = xt_data(1:cut,:);

    % Initialize the logical array
    logical_array = false(height(cell_array), 1);

    for i = 1 : height(cell_array)
        % Check if the row has all double values
        if all(cellfun(@(x) isa(x, "double"), cell_array(i, :)))
            logical_array(i) = 1;
            continue
        end

        % Check if the row contains any missing values
        for j = 1 : width(cell_array)
            if ismissing(cell_array{i,j})
                logical_array(i) = 1;
                break
            end
        end
    end

    logical_array = ~logical_array; % Reverse the bool
    header = cell_array(logical_array, :); % Get the header

    % Check if all the rows have missing values
    if height(header) == 0
        header = cell(1, width(cell_array));
        for i = 1 : width(header)
            header_str = sprintf("XT_Channel_%03d", i);
            header{i} = header_str;
        end
    else
        % Assume the first row without missing value is header
        header = header(1,:); 
    end
end