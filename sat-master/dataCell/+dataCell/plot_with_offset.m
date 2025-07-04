%% dataCell.plot_with_offset
% Extracted plotter, originally within XtDataCell
% 
% It is commonly called from other functions, so it is extracted for use

% Different behavior!~; Only generates a new figure if queried, else
% overrides

% __ Generally used plotter between channels w/ a common offset; 


% Trevor S. Smith, 2025

function f = plot_with_offset(dataArr, OFFSET)
    arguments
        dataArr
        OFFSET double = []; 
    end
    N_PLOT_ROWS = size(dataArr, 1); 

    %// Estimate the ideal offset for co-plotting
    if isempty(OFFSET)      
        maxVal = max(max(abs(diff(dataArr,1)))); 
        offset = 0.5*maxVal; 
    else
        offset = OFFSET; 
    end

    if nargout >0
        f = figure; 
    end

    xMin = inf; 
    xMax = -inf; 
    for m = 1:N_PLOT_ROWS
        xt = dataArr(m,:)-(m-1)*offset; 
        xMax = max(xMax, min(max(xt), offset) ); %up to +1 offset; 
        xMin = min(xMin, max(min(xt), -(m)*offset) );
        if all(isnan(xt))
            %/ 'missing/nan' values
            plot(-(m-1)*offset*ones(size(xt)), 'LineStyle',':'); 
        end
        plot(xt); 
        hold on; 
    end
    if m == 1
        %__ single channels get full bandwidth
        xMax = max(xt); 
        xMin = min(xt); 
    end
    % __ Patch 6.8.24

    yvect = -(N_PLOT_ROWS-1)*offset:offset:0; 
    yticks(yvect); 

    % __ 

    %// Rewindow axes to center on data 
    axis([-inf, inf,xMin, xMax]); 
    ylabel(strcat("Channel Offset = ", num2str(offset))); 
    title("Co-Plotted X(t) Data")
end