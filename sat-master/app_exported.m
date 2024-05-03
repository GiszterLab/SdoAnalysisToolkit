classdef app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        Slider                       matlab.ui.control.Slider
        SliderLabel                  matlab.ui.control.Label
        FilterStdEditField           matlab.ui.control.NumericEditField
        FilterStdEditFieldLabel      matlab.ui.control.Label
        FilterWidthEditField         matlab.ui.control.NumericEditField
        FilterWidthEditFieldLabel    matlab.ui.control.Label
        NShiftEditField              matlab.ui.control.NumericEditField
        NShiftEditFieldLabel         matlab.ui.control.Label
        NoofEventsEditField          matlab.ui.control.NumericEditField
        NoofEventsEditFieldLabel     matlab.ui.control.Label
        ZDelayEditField              matlab.ui.control.NumericEditField
        ZDelayEditFieldLabel         matlab.ui.control.Label
        Px1DuraMsSpinner             matlab.ui.control.Spinner
        Px1DuraMsSpinnerLabel        matlab.ui.control.Label
        Px0DuraMsSpinner             matlab.ui.control.Spinner
        Px0DuraMsSpinnerLabel        matlab.ui.control.Label
        NoofBinsSpinner              matlab.ui.control.Spinner
        NoofBinsSpinnerLabel         matlab.ui.control.Label
        ChannelAmpMinEditField       matlab.ui.control.NumericEditField
        ChannelAmpMinEditFieldLabel  matlab.ui.control.Label
        ChannelAmpMaxEditField       matlab.ui.control.NumericEditField
        ChannelAmpMaxEditFieldLabel  matlab.ui.control.Label
        MaxModeDropDown              matlab.ui.control.DropDown
        MaxModeDropDownLabel         matlab.ui.control.Label
        MapMethodDropDown            matlab.ui.control.DropDown
        MapMethodDropDownLabel       matlab.ui.control.Label
        TabGroup                     matlab.ui.container.TabGroup
        Tab                          matlab.ui.container.Tab
        Tab2                         matlab.ui.container.Tab
        PPChannelsDropDown           matlab.ui.control.DropDown
        PPChannelsDropDownLabel      matlab.ui.control.Label
        XTChannelsDropDown           matlab.ui.control.DropDown
        XTChannelsDropDownLabel      matlab.ui.control.Label
        SelectColumnListBoxLabel     matlab.ui.control.Label
        SelectColumnListBox          matlab.ui.control.ListBox
        TypeFrequencyEditField       matlab.ui.control.NumericEditField
        TypeFrequencyEditFieldLabel  matlab.ui.control.Label
        StirpdPanel                  matlab.ui.container.Panel
        MatrixPanel                  matlab.ui.container.Panel
        DiffusionPanel               matlab.ui.container.Panel
        PlotButton                   matlab.ui.control.Button
        CreateSMMButton              matlab.ui.control.Button
        ImportPPCSVButton            matlab.ui.control.Button
        PPDataLabel                  matlab.ui.control.Label
        xtDataTable3                 matlab.ui.control.Table
        xtDataTable2                 matlab.ui.control.Table
        xtDataTable1                 matlab.ui.control.Table
        ORLabel                      matlab.ui.control.Label
        ImportTimesButton            matlab.ui.control.Button
        NoCheckBoxFrequencyColumn    matlab.ui.control.CheckBox
        YesCheckBoxFrequencyColumn   matlab.ui.control.CheckBox
        PlotSelectedColumnsButton    matlab.ui.control.Button
        IsTimesdataonthefirstcolumnoftheCSVfileLabel  matlab.ui.control.Label
        TimesFrequencyLabel          matlab.ui.control.Label
        PlotAllButton                matlab.ui.control.Button
        ImportXTCSVButton            matlab.ui.control.Button
        UITable                      matlab.ui.control.Table
        xtDataLabel                  matlab.ui.control.Label
        UIAxes                       matlab.ui.control.UIAxes
    end

    
    properties (Access = private)        
        %% Time Series
        xt_file_directory
        
        % This can include times as first column or not
        xt_table % Input Original Time Series Table (Table)
        xt_matrix_data % Input Original Time Series Matrix Data (Matrix)
        
        xt_data_holder % xtData Structure
        xt_data % Time Series Data (Matrix)
        xt_times % Times Data (Matrix)
        xt_frequency % Frequency (Might be an int)

        % Select Data
        xt_selected % Selected xt_data values depending on XT UITable and
                    % ListBox (Matrix)
        xt_selected_struct % Selected struct inside xtDataTable1
        

        %% Point Process
        pp_file_directory

        pp_table % Input Original Point Process Table(Table)
        pp_raw_data % Input Original Point Process Cell Data (Cell)
        
        pp_data_holder % ppData Structure

        pp_selected % Selected Index inside PP Table

        %% DataCells
        xtdc % Datacell for Time Series
        ppdc % Datacell for Point Process
        smm % SDO Multimat Time Series

    end
    
    properties (Access = public)
        NewUITable % Description
        NewTab
    end
    
    methods (Access = private)
        %% Functions to create data cells

        % Create an xtdataHolder object before importing in datacell
        function fillXtDataHolder(app)
            num_column = width(app.xt_data);

            % TODO: Ask Trevor how a user might add new data so you know
            % how to change the parameter instead of forcing it by 1

            app.xt_data_holder = SAT.xtDataHolder_new(1,num_column);
         
            % Helper variable for filling in sensor's names 
            options = detectImportOptions(app.xt_file_directory);
            % Add times data to xtDataHolder
            if height(app.xt_times) > 1
                app.xt_times = app.xt_times';
            end
            app.xt_data_holder{1,1}(1).times = app.xt_times;
                
            for i = 1 : num_column
                % Add raw data to xtDataHolder (Add it as traspose)
                app.xt_data_holder{1,1}(i).raw = app.xt_data(:,i)';

                % Add frequency to xtDataHolder
                if isempty(app.xt_frequency)
                    T = diff(app.xt_data_holder{1,1}(1).times(1:2));
                    app.xt_data_holder{1,1}(i).fs = 1 / T;
                else
                    app.xt_data_holder{1,1}(i).fs = app.xt_frequency;
                end

                % Add envelope data to xtDataHolder
                app.xt_data_holder{1,1}(i).envelope = app.xt_data(:,i)';

                % Add sensor's name to xtDataHolder
                if options.VariableNames(1) ~= "Var1"
                    if app.NoCheckBoxFrequencyColumn.Value
                        app.xt_data_holder{1,1}(i).sensor = options.VariableNames{i};
                    else
                        app.xt_data_holder{1,1}(i).sensor = options.VariableNames{i + 1};
                    end
                else
                    default_column = ["Channel 1","Channel 2", ...
                    "Channel 3","Channel 4","Channel 5","Channel 6","Channel 7", ...
                    "Channel 8","Channel 9","Channel 10","Channel 11","Channel 12", ...
                    "Channel 13","Channel 14","Channel 15","Channel 16","Channel 17", ...
                    "Channel 18","Channel 19","Channel 20","Channel 21","Channel 22", ...
                    "Channel 23","Channel 24","Channel 25","Channel 26","Channel 27", ...
                    "Channel 28","Channel 29","Channel 30"];
                    app.xt_data_holder{1,1}(i).sensor = default_column{i};
                end
            end

            %Fill in frequency to PPDataHolder
            if ~isempty(app.pp_data_holder)
                if isempty(app.pp_data_holder{1,1}(1).fs)
                    for i = 1 : numel(app.pp_raw_data)
                        app.pp_data_holder{1,1}(i).fs = app.xt_frequency;
                    end
                end
            end

            % Enable the createSMM button
            enableCreateSMM(app);
        end

        % Create a ppdataHolder object before importing in datacell
        function fillPPDataHolder(app)
            app.pp_data_holder = SAT.ppDataHolder_new(1, numel(app.pp_raw_data));

            for i = 1 : numel(app.pp_raw_data)
                % Fill in sensors
                % TODO: The sensor value might be filled outside this
                % function
                app.pp_data_holder{1,1}(i).sensor = ['ppChannel_' num2str(i)];
                % Fill in times
                app.pp_data_holder{1,1}(i).times = app.pp_raw_data{i};

                % Add frequency to PPDataHolder
                if ~isempty(app.xt_frequency)
                    app.pp_data_holder{1,1}(i).fs = app.xt_frequency;
                end

                % Fill in envelope (Initially the same with times)
                app.pp_data_holder{1,1}(i).envelope = app.pp_raw_data{i};

                % Fill in nEvents
                app.pp_data_holder{1,1}(i).nEvents = width(app.pp_raw_data{i});
            end

            % Enable the createSMM button
            enableCreateSMM(app);
        end

        % Create the XT datacell object by importing the data
        function createXtDataCell(app)
            app.xtdc = xtDataCell(1, length(app.xt_data_holder{1,1}));
            app.xtdc.import(app.xt_data_holder);
        end

        % Create the PP datacell object by importing the filled object
        function createPPDataCell(app)
            app.ppdc = ppDataCell(1, length(app.pp_data_holder{1,1}));
            app.ppdc.import(app.pp_data_holder);
        end

        % Create SMM object and compute it with filled XT datacell object
        % and PP datacell object
        function createSMM(app)
            % Initialize the SMM object
            app.smm = sdoMultiMat();
            
            % Create a indeterminate progress bar while computing SMM
            d = uiprogressdlg(app.UIFigure,'Title','Computing SMM',...
            'Indeterminate','on');
            app.smm.compute(app.xtdc, app.ppdc, 1, 1);
            close(d);

            % Enable the plot button for SMM
            enablePlotSMM(app);
        end

        function plotSMM(app)
            % Find the channel number for xt and pp
            xt_select_channel = app.XTChannelsDropDown.Value;
            pp_select_channel = app.PPChannelsDropDown.Value;
            xt_column_number = find(cellfun(@(x) strcmp(x, xt_select_channel), ...
                app.XTChannelsDropDown.Items));
            pp_column_number = find(cellfun(@(x) strcmp(x, pp_select_channel), ...
                app.PPChannelsDropDown.Items));

            app.smm.plotMatrix(xt_column_number, pp_column_number);
            % Only the children of figure(axis) can be copied into UIPanel
            % so manually copy the properties
            fig = gcf;
            axis = fig.Children;
            axis_copy = copyobj(axis, app.MatrixPanel);
            % Copy the Title and Labels
            axis_copy.Title.String = axis.Title.String;
            axis_copy.XLabel = axis.XLabel; 
            axis_copy.YLabel = axis.YLabel;
            % Copy the X and Y Ticks and Limits
            axis_copy.XLim = axis.XLim; 
            axis_copy.YLim = axis.YLim;
            axis_copy.XTick = axis.XTick;
            axis_copy.YTick = axis.YTick;
            % Copy the colormap
            axis_copy.Colormap = axis.Colormap;
            % Close the figure after copying
            close(fig);

            % Same with the above but this plot is on another UIPanel
            % The children of the below figure is a group object so take
            % the second object as it is the required axis
            app.smm.plotStirpd(xt_column_number, pp_column_number);
            fig = gcf;
            axis = fig.Children(2);
            axis_copy = copyobj(axis, app.StirpdPanel);
            % Copy the Properties
            axis_copy.Title.String = axis.Title.String;
            axis_copy.XLabel = axis.XLabel; 
            axis_copy.YLabel = axis.YLabel;
            axis_copy.XLim = axis.XLim; 
            axis_copy.YLim = axis.YLim;
            axis_copy.XTick = axis.XTick;
            axis_copy.YTick = axis.YTick;
            axis_copy.Colormap = axis.Colormap;
            % Close the figure after copying
            close(fig)

            % Plot all the smm plots
            app.smm.plot(xt_column_number, pp_column_number);
            % Find the third plot and copy it to UIPanel
            figures = findobj('type', 'figure');
            desired_figure_number = numel(figures) - 2;
            a = figures(desired_figure_number);
            copyobj(a.Children, app.DiffusionPanel);
            % Close the figure after copying desired plot
            close(figures);
        end

        %% Three helper functions used for displaying on UITables

        % Tables need to have only numerical values
        % Change doubles into table
        function double_table = doubleToTable(app, double_matrix)
            double_table = table();

            % Trapose the matrix if height == 1 for better displablity
            if height(double_matrix) == 1
                double_matrix = double_matrix';
            end

            for i = 1 : width(double_matrix)
                double_table = addvars(double_table, double_matrix(:,i));
            end 
        end


        % Change numerical table into doubles
        function double_matrix =  tableToDouble(app, double_table)
            % Allocate the matrix
            double_matrix = ones(height(double_table), width(double_table));
            for i = 1 : width(double_table)
                double_matrix(:,i) = double_table{:,i};
            end
        end


        % Change doubles data inside structure to char
        function new_struct = modifyToCharInStruct(app, old_struct)
            new_struct = old_struct;

            % Return the coloum names(cell) of the struct
            field_names = fieldnames(new_struct);
            
            % Loop thorught the columns
            for i = 1 : length(field_names)
                field_name = field_names{i};
                
                % Check if the column has doubles inside it
                if isa(new_struct(1).(field_name), 'double')
                    % Create a new struct for chars
                    char_struct = struct(); 
                    
                    % Loop through the rows of each column
                    for j = 1 : numel(new_struct)
                        field_value = new_struct(j).(field_name);

                        % Do not change the scalar double into char
                        if ~isempty(field_value) && numel(field_value) ~= 1
                            field_value_string = sprintf('%dx%d %s', ...
                                size(field_value, 1), size(field_value, 2), class(field_value));
                            char_struct(j).(field_name) = field_value_string;
                            new_struct(j).(field_name) = char_struct(j).(field_name);
                        elseif isempty(field_value)
                            field_value_string = '[]';
                            char_struct(j).(field_name) = field_value_string;
                            new_struct(j).(field_name) = char_struct(j).(field_name);
                        end
                    end
                end
            end
        end

        %% Interactivity

        % Enable Yes/No Checkbox
        function enableYesNoCheckbox (app)
            app.YesCheckBoxFrequencyColumn.Enable = "on";
            app.NoCheckBoxFrequencyColumn.Enable = "on";
        end

        % Enable all the boxes related to XTData
        function enableXTBoxes (app)
            app.UITable.Enable = "on";
            app.PlotAllButton.Enable = "on";
            app.PlotSelectedColumnsButton.Enable = "on";
            app.SelectColumnListBox.Enable = "on";
        end

        % Enable the import times/frequency of 'no' button of XTData
        function enableXTNoResultants (app)
            app.ImportTimesButton.Visible = "on";
            app.TypeFrequencyEditField.Visible = "on";
            app.TypeFrequencyEditFieldLabel.Visible = "on";
            app.ORLabel.Visible = "on";
        end
        
        % Enable createSMM button
        % This depends on whether both XTdata and PPdata exist.
        function enableCreateSMM (app)
            yes_check_box = app.YesCheckBoxFrequencyColumn.Value;
            no_check_box = app.NoCheckBoxFrequencyColumn.Value;
            if (yes_check_box || no_check_box) && ~isempty(app.pp_raw_data)
                app.CreateSMMButton.Enable = "on";
            end
        end

        % Enable the plot button for SMM
        % This depends on whether SMM object is created
        function enablePlotSMM (app)
            if app.CreateSMMButton.Enable == "on" && ~isempty(app.smm)
                app.PlotButton.Enable = "on";
            end
        end
    
        % Disable Yes/No Checkbox
        function disableYesNoCheckbox (app)
            app.YesCheckBoxFrequencyColumn.Enable = "off";
            app.NoCheckBoxFrequencyColumn.Enable = "off";
        end

        % Disable all the boxes related to XTData
        function disableXTBoxes (app)
            % Disable the graph and plotting
            if app.UITable.Enable == "on"
                app.UITable.ColumnName = {};
                app.UITable.Data = {};
            end
            app.UITable.Enable = "off";
            app.PlotAllButton.Enable = "off";
            app.PlotSelectedColumnsButton.Enable = "off";
            app.SelectColumnListBox.Enable = "off";
        end

        % Disable the import times/frequency of 'no' button of XTData
        function disableXTNoResultants (app)
            app.ImportTimesButton.Visible = "off";
            app.TypeFrequencyEditField.Visible = "off";
            app.TypeFrequencyEditFieldLabel.Visible = "off";
            app.ORLabel.Visible = "off";
        end

        % Disable the buttons for creating and plotting SMM
        function disableSMM (app)
            app.CreateSMMButton.Enable = "off";
            app.PlotButton.Enable = "off";
        end
        
        % Disable everything
        function disable (app)
            % Reset the Yes/No button for time Question in first coloumn
            app.YesCheckBoxFrequencyColumn.Value = 0;
            app.NoCheckBoxFrequencyColumn.Value = 0;

            disableYesNoCheckbox(app);
            disableXTBoxes(app);
            disableXTNoResultants(app);

            % Disable the SMM buttons if enabled
            if app.CreateSMMButton.Enable == "on"
                disableSMM(app);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: ImportXTCSVButton
        function ImportXTCSVButtonPushed(app, event)
            % Get File Path
            [file, path] = uigetfile('*.*');
            app.xt_file_directory = [path file];
            % app.xt_file_directory = "D:\PMK Files\Jobs\Research Cooridinator\UpdatedSDOAnalysis\SdoAnalysisToolkit\sat-master\emg_sample_data_w_times.txt";

            % Get the matrix data of time series
            try
                app.xt_matrix_data = readmatrix(app.xt_file_directory);
                app.xt_table = readtable(app.xt_file_directory);
                enableYesNoCheckbox(app);
            catch
                disable(app);
            end
        end

        % Cell selection callback: UITable
        function UITableCellSelection(app, event)
            % Store every cell selected inside variable
            % if selected inside table, event.Indices returns an index
            % matrix (a matrix of row,colomn pairs)
            index_matrix = event.Indices;
            selected_column = unique(index_matrix(:,2));
            app.xt_selected = app.xt_data(:,selected_column(1):selected_column(end));
             
        end

        % Button pushed function: PlotAllButton
        function PlotAllButtonPushed(app, event)
            plot(app.UIAxes, app.xt_data);
        end

        % Value changed function: YesCheckBoxFrequencyColumn
        function YesCheckBoxFrequencyColumnValueChanged(app, event)
            % Reset UITable
            app.UITable.Data = [];
            
            value = app.YesCheckBoxFrequencyColumn.Value;
            if value
                app.NoCheckBoxFrequencyColumn.Value = 0;
                enableXTBoxes(app);

                % Disable the import times/frequency of 'no' button
                disableXTNoResultants(app);
                
                % Storing time series data and times data
                app.xt_data = app.xt_matrix_data(:,2:end);
                app.xt_times = app.xt_matrix_data(:,1); 

                %% Display Table

                % For Display
                display_table = app.xt_table;
                display_table(:,1) = []; % Remove first column

                options = detectImportOptions(app.xt_file_directory);
                % Set column name accordingly
                if options.VariableNames(1) ~= "Var1"
                    app.UITable.ColumnName = display_table.Properties.VariableNames;
                else
                    default_column = ["Channel 1","Channel 2", ...
                    "Channel 3","Channel 4","Channel 5","Channel 6","Channel 7", ...
                    "Channel 8","Channel 9","Channel 10","Channel 11","Channel 12", ...
                    "Channel 13","Channel 14","Channel 15","Channel 16","Channel 17", ...
                    "Channel 18","Channel 19","Channel 20","Channel 21","Channel 22", ...
                    "Channel 23","Channel 24","Channel 25","Channel 26","Channel 27", ...
                    "Channel 28","Channel 29","Channel 30"];
                    app.UITable.ColumnName = default_column(1:width(app.xt_data));
                end

                % I am appending the data to the original table.
                app.UITable.Data = [app.UITable.Data; display_table];
                
                % Modify the column list box
                app.SelectColumnListBox.Items = app.UITable.ColumnName(1:width(app.xt_data));             

                % Calculation
                fillXtDataHolder(app);

                % Display data for xtDataCell class
                app.xtDataTable1.Visible = "on";
                xtClassData = cell2table(app.xt_data_holder);
                app.xtDataTable1.Data = xtClassData;

                % Display data for Drop-Down Menu
                for i = 1 : width(app.xt_data)
                    app.XTChannelsDropDown.Items{i} = app.xt_data_holder{1,1}(i).sensor;
                end
                
            end            
        end

        % Value changed function: NoCheckBoxFrequencyColumn
        function NoCheckBoxFrequencyColumnValueChanged(app, event)
            % Reset UITable
            app.UITable.Data = [];
            
            value = app.NoCheckBoxFrequencyColumn.Value;
            if value
                app.YesCheckBoxFrequencyColumn.Value = 0;
                enableXTBoxes(app);
                enableXTNoResultants(app);
                
                % Storing time series data and times data
                app.xt_data = app.xt_matrix_data; 

                %% Display Table

                % For Display
                display_table = app.xt_table;

                options = detectImportOptions(app.xt_file_directory);
                % Set column name accordingly
                if options.VariableNames(1) ~= "Var1"
                    app.UITable.ColumnName = display_table.Properties.VariableNames;
                else
                    default_column = ["Channel 1","Channel 2", ...
                    "Channel 3","Channel 4","Channel 5","Channel 6","Channel 7", ...
                    "Channel 8","Channel 9","Channel 10","Channel 11","Channel 12", ...
                    "Channel 13","Channel 14","Channel 15","Channel 16","Channel 17", ...
                    "Channel 18","Channel 19","Channel 20","Channel 21","Channel 22", ...
                    "Channel 23","Channel 24","Channel 25","Channel 26","Channel 27", ...
                    "Channel 28","Channel 29","Channel 30"];
                    app.UITable.ColumnName = default_column(1:width(app.xt_data));
                end

                % I am appending the data to the original table.
                app.UITable.Data = [app.UITable.Data; display_table]; 

                % Modify the column list box    
                app.SelectColumnListBox.Items = app.UITable.ColumnName;               
            end

        end

        % Button pushed function: PlotSelectedColumnsButton
        function PlotSelectedColumnsButtonPushed(app, event)
            plot(app.UIAxes, app.xt_selected);
        end

        % Value changed function: SelectColumnListBox
        function SelectColumnListBoxValueChanged(app, event)
            selected_value = app.SelectColumnListBox.Value;
            
            % It's necessary to copy the table data with correct column
            % variables since matlab changed the column name to default one
            table_data = app.UITable.Data;
            table_data.Properties.VariableNames = app.UITable.ColumnName;

            selected_matrix = ones(height(app.xt_data),length(selected_value)); % Allocate the matrix
            for i = 1 : length(selected_value)
                column = selected_value{i};
                selected_matrix(:,i) = table_data{:,column};
            end

            app.xt_selected = selected_matrix;
            
        end

        % Button pushed function: ImportTimesButton
        function ImportTimesButtonPushed(app, event)
            [file, path] = uigetfile('*.*');
            file_directory = [path file];

            % Check if user selects a file
            if file ~= 0
                app.xt_times = readmatrix(file_directory);
                
                % Calculation
                fillXtDataHolder(app);  
            
                % Add data for the class table
                xtClassData = cell2table(app.xt_data_holder);
                app.xtDataTable1.Data = xtClassData;
    
                % Display data for Drop-Down Menu
                for i = 1 : width(app.xt_data)
                    app.XTChannelsDropDown.Items{i} = app.xt_data_holder{1,1}(i).sensor;
                end
            end
        end

        % Value changed function: TypeFrequencyEditField
        function TypeFrequencyEditFieldValueChanged(app, event)
            app.xt_frequency = app.TypeFrequencyEditField.Value;

            % Change frequency to time
            time_interval = 1 / app.xt_frequency;
            % Input the times data into app.xt_times
            app.xt_times = zeros(1, height(app.xt_data));
            current_time = time_interval;
            i = 1;
            while i <= height(app.xt_data)
                app.xt_times(i) = current_time;
                current_time = current_time + time_interval;
                i = i + 1;
            end

            % Calculation
            fillXtDataHolder(app);  
        
            % Add data for the class table
            xtClassData = cell2table(app.xt_data_holder);
            app.xtDataTable1.Data = xtClassData;

            % Display data for Drop-Down Menu
            for i = 1 : width(app.xt_data)
                app.XTChannelsDropDown.Items{i} = app.xt_data_holder{1,1}(i).sensor;
            end
        end

        % Double-clicked callback: xtDataTable1
        function xtDataTable1DoubleClicked(app, event)
            displayRow = event.InteractionInformation.DisplayRow;
            displayColumn = event.InteractionInformation.DisplayColumn;

            % Display on new table only when a cell is double-clicked
            if ~ (isempty(displayRow) || isempty(displayColumn))
                % First the table will return a cell so you have to select
                % the data again to get a struct
                app.xt_selected_struct = app.xtDataTable1.Data{app.xtDataTable1.Selection(1), app.xtDataTable1.Selection(2)}{1,1};

                % TODO: Fix the app inside function parameters below

                % Change the doubles to char for effiency and for displaying
                selected_new_struct = modifyToCharInStruct(app, app.xt_selected_struct);
                selected_cell_table = struct2table(selected_new_struct);

                % Display on table
                app.xtDataTable2.Visible = "on";
                app.xtDataTable2.Data = selected_cell_table;
                app.xtDataTable2.ColumnName = selected_cell_table.Properties.VariableNames;
            end
            
        end

        % Double-clicked callback: xtDataTable2
        function xtDataTable2DoubleClicked(app, event)
            displayRow = event.InteractionInformation.DisplayRow;
            displayColumn = event.InteractionInformation.DisplayColumn;

            % TODO: Display for char data

            % Display on new table only when a cell is double-clicked
            if ~ (isempty(displayRow) || isempty(displayColumn))
                columns = fieldnames(app.xt_selected_struct);
                column = columns{displayColumn};
                data_to_display = app.xt_selected_struct(displayRow).(column);

                % Trapose the doubles for better display
                if height(data_to_display) == 1 && isa(data_to_display, 'double')
                    data_to_display = data_to_display';
                end

                % Display on table
                app.xtDataTable3.Visible = "on";
                app.xtDataTable3.Data = data_to_display;
                app.xtDataTable3.ColumnName = sprintf("%s(%d)",column, displayRow);
            end
            
        end

        % Button pushed function: ImportPPCSVButton
        function ImportPPCSVButtonPushed(app, event)
            % Disable the plot button to enforce the user into creating the
            % new SMM
            app.PlotButton.Enable = "off";

            % Get File Path
            [file, path] = uigetfile('*.*');
            app.pp_file_directory = [path file];
            % app.pp_file_directory = "D:\PMK Files\Jobs\Research Cooridinator\UpdatedSDOAnalysis\SdoAnalysisToolkit\sat-master\pp_sample_data.txt";
            % file = 1;

            % Check if user selects a file
            if file ~= 0
                options = detectImportOptions(app.pp_file_directory);
                
                % Only if the matrix is double and double
                if options.VariableTypes{1} == "double" && options.VariableTypes{2} == "double"
                    tmp_matrix_data = readmatrix(app.pp_file_directory);
                    sensors = unique(tmp_matrix_data(:,2));
                    for i = 1 : numel(sensors)
                        cell_data{i} = transpose(tmp_matrix_data(tmp_matrix_data(:,2) == i));
                    end
                end
    
                % Store the matrix and table data for display (LATER USE)
                app.pp_raw_data = transpose(cell_data);
                % Get the raw table data of point process
                app.pp_table = cell2table(app.pp_raw_data, "VariableNames", "Raw");
                
                % Fill in the DataCell
                fillPPDataHolder(app);
    
                % Display sensors in the dropdown menu
                app.PPChannelsDropDown.Items = {app.pp_data_holder{1,1}.sensor};
            end
        end

        % Button pushed function: CreateSMMButton
        function CreateSMMButtonPushed(app, event)
            createXtDataCell(app);
            createPPDataCell(app);
            createSMM(app);
        end

        % Button pushed function: PlotButton
        function PlotButtonPushed(app, event)
            plotSMM(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1179 2093];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Scrollable = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {47, 53, 41, 24, 27, 28, 45, 43, 57, 25, 41, 100, 125, 26, 57, 80, '1.18x', 97, 47};
            app.GridLayout.RowHeight = {47, 300, 33, 250, 22, 37, 22, 22, 22, 22, 22, 22, 300, 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 300, 'fit', 70};
            app.GridLayout.ColumnSpacing = 1.66666666666667;
            app.GridLayout.RowSpacing = 7.36956455396569;
            app.GridLayout.Padding = [1.66666666666667 7.36956455396569 1.66666666666667 7.36956455396569];
            app.GridLayout.Scrollable = 'on';

            % Create UIAxes
            app.UIAxes = uiaxes(app.GridLayout);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Layout.Row = 2;
            app.UIAxes.Layout.Column = [2 10];

            % Create xtDataLabel
            app.xtDataLabel = uilabel(app.GridLayout);
            app.xtDataLabel.HorizontalAlignment = 'center';
            app.xtDataLabel.FontSize = 14;
            app.xtDataLabel.FontWeight = 'bold';
            app.xtDataLabel.Layout.Row = 5;
            app.xtDataLabel.Layout.Column = [4 5];
            app.xtDataLabel.Text = 'xtData';

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = '';
            app.UITable.RowName = {};
            app.UITable.CellSelectionCallback = createCallbackFcn(app, @UITableCellSelection, true);
            app.UITable.Enable = 'off';
            app.UITable.Layout.Row = 2;
            app.UITable.Layout.Column = [15 18];

            % Create ImportXTCSVButton
            app.ImportXTCSVButton = uibutton(app.GridLayout, 'push');
            app.ImportXTCSVButton.ButtonPushedFcn = createCallbackFcn(app, @ImportXTCSVButtonPushed, true);
            app.ImportXTCSVButton.WordWrap = 'on';
            app.ImportXTCSVButton.Layout.Row = 6;
            app.ImportXTCSVButton.Layout.Column = [3 6];
            app.ImportXTCSVButton.Text = 'Import XT CSV';

            % Create PlotAllButton
            app.PlotAllButton = uibutton(app.GridLayout, 'push');
            app.PlotAllButton.ButtonPushedFcn = createCallbackFcn(app, @PlotAllButtonPushed, true);
            app.PlotAllButton.Enable = 'off';
            app.PlotAllButton.Layout.Row = 3;
            app.PlotAllButton.Layout.Column = [11 12];
            app.PlotAllButton.Text = 'Plot All';

            % Create TimesFrequencyLabel
            app.TimesFrequencyLabel = uilabel(app.GridLayout);
            app.TimesFrequencyLabel.FontSize = 14;
            app.TimesFrequencyLabel.FontWeight = 'bold';
            app.TimesFrequencyLabel.Layout.Row = 7;
            app.TimesFrequencyLabel.Layout.Column = [3 6];
            app.TimesFrequencyLabel.Text = 'Times/Frequency';

            % Create IsTimesdataonthefirstcolumnoftheCSVfileLabel
            app.IsTimesdataonthefirstcolumnoftheCSVfileLabel = uilabel(app.GridLayout);
            app.IsTimesdataonthefirstcolumnoftheCSVfileLabel.Layout.Row = 8;
            app.IsTimesdataonthefirstcolumnoftheCSVfileLabel.Layout.Column = [2 8];
            app.IsTimesdataonthefirstcolumnoftheCSVfileLabel.Text = 'Is Times data on the first column of the CSV file?';

            % Create PlotSelectedColumnsButton
            app.PlotSelectedColumnsButton = uibutton(app.GridLayout, 'push');
            app.PlotSelectedColumnsButton.ButtonPushedFcn = createCallbackFcn(app, @PlotSelectedColumnsButtonPushed, true);
            app.PlotSelectedColumnsButton.Enable = 'off';
            app.PlotSelectedColumnsButton.Layout.Row = 3;
            app.PlotSelectedColumnsButton.Layout.Column = 13;
            app.PlotSelectedColumnsButton.Text = 'Plot Selected Columns';

            % Create YesCheckBoxFrequencyColumn
            app.YesCheckBoxFrequencyColumn = uicheckbox(app.GridLayout);
            app.YesCheckBoxFrequencyColumn.ValueChangedFcn = createCallbackFcn(app, @YesCheckBoxFrequencyColumnValueChanged, true);
            app.YesCheckBoxFrequencyColumn.Enable = 'off';
            app.YesCheckBoxFrequencyColumn.Text = 'Yes';
            app.YesCheckBoxFrequencyColumn.Layout.Row = 9;
            app.YesCheckBoxFrequencyColumn.Layout.Column = 3;

            % Create NoCheckBoxFrequencyColumn
            app.NoCheckBoxFrequencyColumn = uicheckbox(app.GridLayout);
            app.NoCheckBoxFrequencyColumn.ValueChangedFcn = createCallbackFcn(app, @NoCheckBoxFrequencyColumnValueChanged, true);
            app.NoCheckBoxFrequencyColumn.Enable = 'off';
            app.NoCheckBoxFrequencyColumn.Text = 'No';
            app.NoCheckBoxFrequencyColumn.Layout.Row = 9;
            app.NoCheckBoxFrequencyColumn.Layout.Column = [5 6];

            % Create ImportTimesButton
            app.ImportTimesButton = uibutton(app.GridLayout, 'push');
            app.ImportTimesButton.ButtonPushedFcn = createCallbackFcn(app, @ImportTimesButtonPushed, true);
            app.ImportTimesButton.Visible = 'off';
            app.ImportTimesButton.Layout.Row = 10;
            app.ImportTimesButton.Layout.Column = [1 2];
            app.ImportTimesButton.Text = 'Import Times';

            % Create ORLabel
            app.ORLabel = uilabel(app.GridLayout);
            app.ORLabel.HorizontalAlignment = 'center';
            app.ORLabel.FontColor = [1 0 0];
            app.ORLabel.Visible = 'off';
            app.ORLabel.Layout.Row = 10;
            app.ORLabel.Layout.Column = 4;
            app.ORLabel.Text = 'OR';

            % Create xtDataTable1
            app.xtDataTable1 = uitable(app.GridLayout);
            app.xtDataTable1.ColumnName = '';
            app.xtDataTable1.RowName = {};
            app.xtDataTable1.DoubleClickedFcn = createCallbackFcn(app, @xtDataTable1DoubleClicked, true);
            app.xtDataTable1.Visible = 'off';
            app.xtDataTable1.Layout.Row = 4;
            app.xtDataTable1.Layout.Column = [2 9];

            % Create xtDataTable2
            app.xtDataTable2 = uitable(app.GridLayout);
            app.xtDataTable2.ColumnName = '';
            app.xtDataTable2.RowName = {};
            app.xtDataTable2.DoubleClickedFcn = createCallbackFcn(app, @xtDataTable2DoubleClicked, true);
            app.xtDataTable2.Visible = 'off';
            app.xtDataTable2.Layout.Row = 4;
            app.xtDataTable2.Layout.Column = [11 16];

            % Create xtDataTable3
            app.xtDataTable3 = uitable(app.GridLayout);
            app.xtDataTable3.ColumnName = '';
            app.xtDataTable3.RowName = {};
            app.xtDataTable3.Visible = 'off';
            app.xtDataTable3.Layout.Row = 4;
            app.xtDataTable3.Layout.Column = 18;

            % Create PPDataLabel
            app.PPDataLabel = uilabel(app.GridLayout);
            app.PPDataLabel.Layout.Row = 5;
            app.PPDataLabel.Layout.Column = 16;
            app.PPDataLabel.Text = 'PPData';

            % Create ImportPPCSVButton
            app.ImportPPCSVButton = uibutton(app.GridLayout, 'push');
            app.ImportPPCSVButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPPCSVButtonPushed, true);
            app.ImportPPCSVButton.WordWrap = 'on';
            app.ImportPPCSVButton.Layout.Row = 6;
            app.ImportPPCSVButton.Layout.Column = [15 16];
            app.ImportPPCSVButton.Text = 'Import PP CSV';

            % Create CreateSMMButton
            app.CreateSMMButton = uibutton(app.GridLayout, 'push');
            app.CreateSMMButton.ButtonPushedFcn = createCallbackFcn(app, @CreateSMMButtonPushed, true);
            app.CreateSMMButton.Enable = 'off';
            app.CreateSMMButton.Layout.Row = 11;
            app.CreateSMMButton.Layout.Column = 13;
            app.CreateSMMButton.Text = 'CreateSMM';

            % Create PlotButton
            app.PlotButton = uibutton(app.GridLayout, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Enable = 'off';
            app.PlotButton.Layout.Row = 12;
            app.PlotButton.Layout.Column = 13;
            app.PlotButton.Text = 'Plot';

            % Create DiffusionPanel
            app.DiffusionPanel = uipanel(app.GridLayout);
            app.DiffusionPanel.Layout.Row = 21;
            app.DiffusionPanel.Layout.Column = [8 16];

            % Create MatrixPanel
            app.MatrixPanel = uipanel(app.GridLayout);
            app.MatrixPanel.Layout.Row = 13;
            app.MatrixPanel.Layout.Column = [2 11];

            % Create StirpdPanel
            app.StirpdPanel = uipanel(app.GridLayout);
            app.StirpdPanel.Layout.Row = 13;
            app.StirpdPanel.Layout.Column = [14 18];

            % Create TypeFrequencyEditFieldLabel
            app.TypeFrequencyEditFieldLabel = uilabel(app.GridLayout);
            app.TypeFrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.TypeFrequencyEditFieldLabel.Visible = 'off';
            app.TypeFrequencyEditFieldLabel.Layout.Row = 10;
            app.TypeFrequencyEditFieldLabel.Layout.Column = [6 8];
            app.TypeFrequencyEditFieldLabel.Text = 'Type Frequency';

            % Create TypeFrequencyEditField
            app.TypeFrequencyEditField = uieditfield(app.GridLayout, 'numeric');
            app.TypeFrequencyEditField.ValueChangedFcn = createCallbackFcn(app, @TypeFrequencyEditFieldValueChanged, true);
            app.TypeFrequencyEditField.Visible = 'off';
            app.TypeFrequencyEditField.Layout.Row = 10;
            app.TypeFrequencyEditField.Layout.Column = [9 10];

            % Create SelectColumnListBox
            app.SelectColumnListBox = uilistbox(app.GridLayout);
            app.SelectColumnListBox.Items = {};
            app.SelectColumnListBox.Multiselect = 'on';
            app.SelectColumnListBox.ValueChangedFcn = createCallbackFcn(app, @SelectColumnListBoxValueChanged, true);
            app.SelectColumnListBox.Enable = 'off';
            app.SelectColumnListBox.Layout.Row = 2;
            app.SelectColumnListBox.Layout.Column = 13;
            app.SelectColumnListBox.Value = {};

            % Create SelectColumnListBoxLabel
            app.SelectColumnListBoxLabel = uilabel(app.GridLayout);
            app.SelectColumnListBoxLabel.HorizontalAlignment = 'right';
            app.SelectColumnListBoxLabel.Enable = 'off';
            app.SelectColumnListBoxLabel.Layout.Row = 2;
            app.SelectColumnListBoxLabel.Layout.Column = 12;
            app.SelectColumnListBoxLabel.Text = 'Select Column';

            % Create XTChannelsDropDownLabel
            app.XTChannelsDropDownLabel = uilabel(app.GridLayout);
            app.XTChannelsDropDownLabel.HorizontalAlignment = 'center';
            app.XTChannelsDropDownLabel.Layout.Row = 12;
            app.XTChannelsDropDownLabel.Layout.Column = [3 5];
            app.XTChannelsDropDownLabel.Text = 'XT Channels';

            % Create XTChannelsDropDown
            app.XTChannelsDropDown = uidropdown(app.GridLayout);
            app.XTChannelsDropDown.Items = {};
            app.XTChannelsDropDown.Layout.Row = 12;
            app.XTChannelsDropDown.Layout.Column = [6 8];
            app.XTChannelsDropDown.Value = {};

            % Create PPChannelsDropDownLabel
            app.PPChannelsDropDownLabel = uilabel(app.GridLayout);
            app.PPChannelsDropDownLabel.Layout.Row = 12;
            app.PPChannelsDropDownLabel.Layout.Column = 16;
            app.PPChannelsDropDownLabel.Text = 'PP Channels';

            % Create PPChannelsDropDown
            app.PPChannelsDropDown = uidropdown(app.GridLayout);
            app.PPChannelsDropDown.Items = {};
            app.PPChannelsDropDown.Layout.Row = 12;
            app.PPChannelsDropDown.Layout.Column = 17;
            app.PPChannelsDropDown.Value = {};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 22;
            app.TabGroup.Layout.Column = [3 12];

            % Create Tab
            app.Tab = uitab(app.TabGroup);
            app.Tab.Title = 'Tab';

            % Create Tab2
            app.Tab2 = uitab(app.TabGroup);
            app.Tab2.Title = 'Tab2';

            % Create MapMethodDropDownLabel
            app.MapMethodDropDownLabel = uilabel(app.GridLayout);
            app.MapMethodDropDownLabel.HorizontalAlignment = 'center';
            app.MapMethodDropDownLabel.Layout.Row = 16;
            app.MapMethodDropDownLabel.Layout.Column = [2 3];
            app.MapMethodDropDownLabel.Text = 'Map Method';

            % Create MapMethodDropDown
            app.MapMethodDropDown = uidropdown(app.GridLayout);
            app.MapMethodDropDown.Layout.Row = 16;
            app.MapMethodDropDown.Layout.Column = [4 7];

            % Create MaxModeDropDownLabel
            app.MaxModeDropDownLabel = uilabel(app.GridLayout);
            app.MaxModeDropDownLabel.HorizontalAlignment = 'center';
            app.MaxModeDropDownLabel.Layout.Row = 17;
            app.MaxModeDropDownLabel.Layout.Column = [2 3];
            app.MaxModeDropDownLabel.Text = 'Max Mode';

            % Create MaxModeDropDown
            app.MaxModeDropDown = uidropdown(app.GridLayout);
            app.MaxModeDropDown.Layout.Row = 17;
            app.MaxModeDropDown.Layout.Column = [4 7];

            % Create ChannelAmpMaxEditFieldLabel
            app.ChannelAmpMaxEditFieldLabel = uilabel(app.GridLayout);
            app.ChannelAmpMaxEditFieldLabel.HorizontalAlignment = 'center';
            app.ChannelAmpMaxEditFieldLabel.Layout.Row = 14;
            app.ChannelAmpMaxEditFieldLabel.Layout.Column = [2 4];
            app.ChannelAmpMaxEditFieldLabel.Text = 'ChannelAmpMax';

            % Create ChannelAmpMaxEditField
            app.ChannelAmpMaxEditField = uieditfield(app.GridLayout, 'numeric');
            app.ChannelAmpMaxEditField.Layout.Row = 14;
            app.ChannelAmpMaxEditField.Layout.Column = [5 7];

            % Create ChannelAmpMinEditFieldLabel
            app.ChannelAmpMinEditFieldLabel = uilabel(app.GridLayout);
            app.ChannelAmpMinEditFieldLabel.HorizontalAlignment = 'center';
            app.ChannelAmpMinEditFieldLabel.Layout.Row = 15;
            app.ChannelAmpMinEditFieldLabel.Layout.Column = [2 4];
            app.ChannelAmpMinEditFieldLabel.Text = 'ChannelAmpMin';

            % Create ChannelAmpMinEditField
            app.ChannelAmpMinEditField = uieditfield(app.GridLayout, 'numeric');
            app.ChannelAmpMinEditField.Layout.Row = 15;
            app.ChannelAmpMinEditField.Layout.Column = [5 7];

            % Create NoofBinsSpinnerLabel
            app.NoofBinsSpinnerLabel = uilabel(app.GridLayout);
            app.NoofBinsSpinnerLabel.HorizontalAlignment = 'center';
            app.NoofBinsSpinnerLabel.Layout.Row = 18;
            app.NoofBinsSpinnerLabel.Layout.Column = [2 3];
            app.NoofBinsSpinnerLabel.Text = 'No. of Bins';

            % Create NoofBinsSpinner
            app.NoofBinsSpinner = uispinner(app.GridLayout);
            app.NoofBinsSpinner.Layout.Row = 18;
            app.NoofBinsSpinner.Layout.Column = [4 7];

            % Create Px0DuraMsSpinnerLabel
            app.Px0DuraMsSpinnerLabel = uilabel(app.GridLayout);
            app.Px0DuraMsSpinnerLabel.HorizontalAlignment = 'center';
            app.Px0DuraMsSpinnerLabel.Layout.Row = 14;
            app.Px0DuraMsSpinnerLabel.Layout.Column = [14 15];
            app.Px0DuraMsSpinnerLabel.Text = 'Px0DuraMs';

            % Create Px0DuraMsSpinner
            app.Px0DuraMsSpinner = uispinner(app.GridLayout);
            app.Px0DuraMsSpinner.Layout.Row = 14;
            app.Px0DuraMsSpinner.Layout.Column = 16;

            % Create Px1DuraMsSpinnerLabel
            app.Px1DuraMsSpinnerLabel = uilabel(app.GridLayout);
            app.Px1DuraMsSpinnerLabel.HorizontalAlignment = 'center';
            app.Px1DuraMsSpinnerLabel.Layout.Row = 15;
            app.Px1DuraMsSpinnerLabel.Layout.Column = [14 15];
            app.Px1DuraMsSpinnerLabel.Text = 'Px1DuraMs';

            % Create Px1DuraMsSpinner
            app.Px1DuraMsSpinner = uispinner(app.GridLayout);
            app.Px1DuraMsSpinner.Layout.Row = 15;
            app.Px1DuraMsSpinner.Layout.Column = 16;

            % Create ZDelayEditFieldLabel
            app.ZDelayEditFieldLabel = uilabel(app.GridLayout);
            app.ZDelayEditFieldLabel.HorizontalAlignment = 'center';
            app.ZDelayEditFieldLabel.Layout.Row = 16;
            app.ZDelayEditFieldLabel.Layout.Column = [14 15];
            app.ZDelayEditFieldLabel.Text = 'Z Delay';

            % Create ZDelayEditField
            app.ZDelayEditField = uieditfield(app.GridLayout, 'numeric');
            app.ZDelayEditField.Layout.Row = 16;
            app.ZDelayEditField.Layout.Column = 16;

            % Create NoofEventsEditFieldLabel
            app.NoofEventsEditFieldLabel = uilabel(app.GridLayout);
            app.NoofEventsEditFieldLabel.HorizontalAlignment = 'center';
            app.NoofEventsEditFieldLabel.Layout.Row = 20;
            app.NoofEventsEditFieldLabel.Layout.Column = [14 15];
            app.NoofEventsEditFieldLabel.Text = 'No. of Events';

            % Create NoofEventsEditField
            app.NoofEventsEditField = uieditfield(app.GridLayout, 'numeric');
            app.NoofEventsEditField.Layout.Row = 20;
            app.NoofEventsEditField.Layout.Column = 16;

            % Create NShiftEditFieldLabel
            app.NShiftEditFieldLabel = uilabel(app.GridLayout);
            app.NShiftEditFieldLabel.HorizontalAlignment = 'center';
            app.NShiftEditFieldLabel.Layout.Row = 17;
            app.NShiftEditFieldLabel.Layout.Column = [14 15];
            app.NShiftEditFieldLabel.Text = 'N Shift';

            % Create NShiftEditField
            app.NShiftEditField = uieditfield(app.GridLayout, 'numeric');
            app.NShiftEditField.Layout.Row = 17;
            app.NShiftEditField.Layout.Column = 16;

            % Create FilterWidthEditFieldLabel
            app.FilterWidthEditFieldLabel = uilabel(app.GridLayout);
            app.FilterWidthEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterWidthEditFieldLabel.Layout.Row = 18;
            app.FilterWidthEditFieldLabel.Layout.Column = [14 15];
            app.FilterWidthEditFieldLabel.Text = 'Filter Width';

            % Create FilterWidthEditField
            app.FilterWidthEditField = uieditfield(app.GridLayout, 'numeric');
            app.FilterWidthEditField.Layout.Row = 18;
            app.FilterWidthEditField.Layout.Column = 16;

            % Create FilterStdEditFieldLabel
            app.FilterStdEditFieldLabel = uilabel(app.GridLayout);
            app.FilterStdEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterStdEditFieldLabel.Layout.Row = 19;
            app.FilterStdEditFieldLabel.Layout.Column = [14 15];
            app.FilterStdEditFieldLabel.Text = 'Filter Std';

            % Create FilterStdEditField
            app.FilterStdEditField = uieditfield(app.GridLayout, 'numeric');
            app.FilterStdEditField.Layout.Row = 19;
            app.FilterStdEditField.Layout.Column = 16;

            % Create SliderLabel
            app.SliderLabel = uilabel(app.GridLayout);
            app.SliderLabel.HorizontalAlignment = 'right';
            app.SliderLabel.Layout.Row = 20;
            app.SliderLabel.Layout.Column = 2;
            app.SliderLabel.Text = 'Slider';

            % Create Slider
            app.Slider = uislider(app.GridLayout);
            app.Slider.Layout.Row = 20;
            app.Slider.Layout.Column = [3 7];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end