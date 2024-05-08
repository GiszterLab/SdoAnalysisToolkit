classdef app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        NoofEventsDropDown           matlab.ui.control.DropDown
        DefaultLabelPPDC             matlab.ui.control.Label
        DefaultLabelFilterStd        matlab.ui.control.Label
        DefaultLabelFilterWidth      matlab.ui.control.Label
        DefaultLabelNShift           matlab.ui.control.Label
        DefaultLabelZDelay           matlab.ui.control.Label
        DefaultLabelPX1              matlab.ui.control.Label
        DefaultLabelPX0              matlab.ui.control.Label
        DefaultLabelXTDC             matlab.ui.control.Label
        DefaultLabelNoOfBins         matlab.ui.control.Label
        DefaultLabelMaxMode          matlab.ui.control.Label
        DefaultLabelMapMethod        matlab.ui.control.Label
        SensorDropDown               matlab.ui.control.DropDown
        SensorDropDownLabel          matlab.ui.control.Label
        SMMLabel                     matlab.ui.control.Label
        XTDCLabel                    matlab.ui.control.Label
        CreateSMMSelectedButton      matlab.ui.control.Button
        NoofEventsEditField          matlab.ui.control.NumericEditField
        NoofEventsEditFieldLabel     matlab.ui.control.Label
        PX1DuraMsEditField           matlab.ui.control.NumericEditField
        PX1DuraMsEditFieldLabel      matlab.ui.control.Label
        PX0DuraMsEditField           matlab.ui.control.NumericEditField
        PX0DuraMsEditFieldLabel      matlab.ui.control.Label
        FilterStdEditField           matlab.ui.control.NumericEditField
        FilterStdEditFieldLabel      matlab.ui.control.Label
        FilterWidthEditField         matlab.ui.control.NumericEditField
        FilterWidthEditFieldLabel    matlab.ui.control.Label
        NShiftEditField              matlab.ui.control.NumericEditField
        NShiftEditFieldLabel         matlab.ui.control.Label
        ZDelayEditField              matlab.ui.control.NumericEditField
        ZDelayEditFieldLabel         matlab.ui.control.Label
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
        XTDCTab                      matlab.ui.container.Tab
        PPDCTab                      matlab.ui.container.Tab
        SMMTab                       matlab.ui.container.Tab
        PPChannelsDropDown           matlab.ui.control.DropDown
        PPChannelsDropDownLabel      matlab.ui.control.Label
        SelectColumnListBoxLabel     matlab.ui.control.Label
        XTChannelsDropDown           matlab.ui.control.DropDown
        XTChannelsDropDownLabel      matlab.ui.control.Label
        SelectColumnListBox          matlab.ui.control.ListBox
        TypeFrequencyEditField       matlab.ui.control.NumericEditField
        TypeFrequencyEditFieldLabel  matlab.ui.control.Label
        StirpdPanel                  matlab.ui.container.Panel
        MatrixPanel                  matlab.ui.container.Panel
        DiffusionPanel               matlab.ui.container.Panel
        PlotButton                   matlab.ui.control.Button
        CreateSMMAllButton           matlab.ui.control.Button
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
        XTDataLabel                  matlab.ui.control.Label
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
        original_xtdc % Original XT DataCell
        sensor_index % Index (Used in changing maximum and minimum value)
       
        ppdc % Datacell for Point Process
        original_ppdc % Original PP DataCell

        smm % SDO Multimat Time Series
        original_smm % Original SMM Data

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
            
            % After filling in, create the DataCell object
            app.createXtDataCell();

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

            % After filling in, create the DataCell object
            app.createPPDataCell();

            % Enable the createSMM button
            enableCreateSMM(app);
        end

        % Create the XT datacell object by importing the data
        function createXtDataCell(app)
            app.xtdc = xtDataCell(1, length(app.xt_data_holder{1,1}));
            app.xtdc.import(app.xt_data_holder);

            % Store the original XT Datacell
            app.original_xtdc = copy(app.xtdc);

            % Enable XT DataCell Variables
            app.enableXTVariables();
            % Display XT DataCell Variables
            app.fillXTVariable();
        end

        % Create the PP datacell object by importing the filled object
        function createPPDataCell(app)
            app.ppdc = ppDataCell(1, length(app.pp_data_holder{1,1}));
            app.ppdc.import(app.pp_data_holder);

            % Store the original PP Datacell
            app.original_ppdc = copy(app.ppdc);
        end

        % Create SMM object and compute it with filled XT datacell object
        % and PP datacell object
        function createSMM(app, xt_index, pp_index)
            % Initialize the SMM object
            app.smm = sdoMultiMat();
            
            % Create a indeterminate progress bar while computing SMM
            d = uiprogressdlg(app.UIFigure,'Title','Computing SMM',...
            'Indeterminate','on');
            if nargin == 1
                app.smm.compute(app.xtdc, app.ppdc);
            elseif nargin == 3
                app.smm.compute(app.xtdc, app.ppdc, xt_index, pp_index);
            end
            close(d);

            % Store the original SMM Data
            app.original_smm = copy(app.smm);

            % Enable the plot button for SMM
            app.enablePlotSMM();
            % Enable the variable boxes for SMM
            app.enableSMMVariables();
            % Display SMM Variables
            app.fillSMMVariable();
        end

        function plotSMM(app)
            % Clear all three Panels
            delete(app.MatrixPanel.Children);
            delete(app.StirpdPanel.Children);
            delete(app.DiffusionPanel.Children);

            % Find the channel number for xt and pp
            if app.smm.nXtChannels == 1 && app.smm.nPpChannels == 1
                xt_column_number = 1;
                pp_column_number = 1;
            else
            xt_select_channel = app.XTChannelsDropDown.Value;
            pp_select_channel = app.PPChannelsDropDown.Value;
            xt_column_number = find(cellfun(@(x) strcmp(x, xt_select_channel), ...
                app.XTChannelsDropDown.Items));
            pp_column_number = find(cellfun(@(x) strcmp(x, pp_select_channel), ...
                app.PPChannelsDropDown.Items));
            end

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

            % TODO: Ask Trevor to implement the diffusion plotting with
            % correct datacell

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

        %% Displaying and Updating DataCell Variables

        function fillXTVariable (app)
            % Sensors
            app.SensorDropDown.Items = app.original_xtdc.sensor;
            app.SensorDropDown.Value = app.SensorDropDown.Items{1};
            
            % Set Limits for ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Limits = [app.original_xtdc.channelAmpMin(1,1) app.original_xtdc.channelAmpMax(1,1)];
            app.ChannelAmpMinEditField.Limits = [app.original_xtdc.channelAmpMin(1,1) app.original_xtdc.channelAmpMax(1,1)];
            % ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Value = app.original_xtdc.channelAmpMax(1,1);
            app.ChannelAmpMinEditField.Value = app.original_xtdc.channelAmpMin(1,1);

            % Map Method and Max Mode list is manually inserted
            % drop down menu
            app.MapMethodDropDown.Value = app.original_xtdc.mapMethod;
            app.MaxModeDropDown.Value = app.original_xtdc.maxMode;

            % No. of Bins
            app.NoofBinsSpinner.Value = app.original_xtdc.nBins;

            % Default Label Values
            app.DefaultLabelMapMethod.Text = app.original_xtdc.mapMethod;
            app.DefaultLabelMaxMode.Text = app.original_xtdc.maxMode;
            app.DefaultLabelNoOfBins.Text = string(app.original_xtdc.nBins);
        end

        function fillSMMVariable (app)
            % px0DuraMs and px1DuraMs
            app.PX0DuraMsEditField.Value = app.original_smm.px0DuraMs;
            app.PX1DuraMsEditField.Value = app.original_smm.px1DuraMs;

            % zDelay and nShift
            app.ZDelayEditField.Value = app.original_smm.zDelay;
            app.NShiftEditField.Value = app.original_smm.nShift;

            % Filter Width and filterStd
            app.FilterWidthEditField.Value = app.original_smm.filterWid;
            app.FilterStdEditField.Value = app.original_smm.filterStd;

            % No. of events used depending on sensors
            app.NoofEventsEditField.Value = app.original_smm.nEventsUsed(1);
            app.NoofEventsDropDown.Items = app.original_smm.sdoStruct.neuronNames;
            % Always show the top option (This is useful when the user
            % decides to create another smm)
            app.NoofEventsDropDown.Value = app.NoofEventsDropDown.Items{1};

            % Default Label Values
            app.DefaultLabelPX0.Text = string(app.original_smm.px0DuraMs);
            app.DefaultLabelPX1.Text = string(app.original_smm.px1DuraMs);
            app.DefaultLabelZDelay.Text = string(app.original_smm.zDelay);
            app.DefaultLabelNShift.Text = string(app.original_smm.nShift);
            app.DefaultLabelFilterWidth.Text = string(app.original_smm.filterWid);
            app.DefaultLabelFilterStd.Text = string(app.original_smm.filterStd);
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
                app.CreateSMMAllButton.Enable = "on";
                app.CreateSMMSelectedButton.Enable = "on";
            end
        end

        % Enable the plot button for SMM
        % This depends on whether SMM object is created
        function enablePlotSMM (app)
            if app.CreateSMMAllButton.Enable == "on" && ~isempty(app.smm)
                app.PlotButton.Enable = "on";
            end
        end

        % Enable XTVariables
        function enableXTVariables (app)
            app.SensorDropDown.Enable = "on";
            app.SensorDropDownLabel.Enable = "on";
            app.ChannelAmpMaxEditField.Enable = "on";
            app.ChannelAmpMaxEditFieldLabel.Enable = "on";
            app.ChannelAmpMinEditField.Enable = "on";
            app.ChannelAmpMinEditFieldLabel.Enable = "on";
            app.MapMethodDropDown.Enable = "on";
            app.MapMethodDropDownLabel.Enable = "on";
            app.MaxModeDropDown.Enable = "on";
            app.MaxModeDropDownLabel.Enable = "on";
            app.NoofBinsSpinner.Enable = "on";
            app.NoofBinsSpinnerLabel.Enable = "on";
        end

        % Enable SMMVariables
        function enableSMMVariables (app)
            app.PX0DuraMsEditField.Enable = "on";
            app.PX0DuraMsEditFieldLabel.Enable = "on";
            app.PX1DuraMsEditField.Enable = "on";
            app.PX1DuraMsEditFieldLabel.Enable = "on";
            app.ZDelayEditField.Enable = "on";
            app.ZDelayEditFieldLabel.Enable = "on";
            app.NShiftEditField.Enable = "on";
            app.NShiftEditFieldLabel.Enable = "on";
            app.FilterWidthEditField.Enable = "on";
            app.FilterWidthEditFieldLabel.Enable = "on";
            app.FilterStdEditField.Enable = "on";
            app.FilterStdEditFieldLabel.Enable = "on";
            app.NoofEventsEditField.Enable = "on";
            app.NoofEventsEditFieldLabel.Enable = "on";
            app.NoofEventsDropDown.Enable = "on";
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
            app.TypeFrequencyEditField.Value = 0;
            app.ORLabel.Visible = "off";
        end

        % Disable the buttons for creating and plotting SMM
        function disableSMM (app)
            app.CreateSMMAllButton.Enable = "off";
            app.CreateSMMSelectedButton.Enable = "off";
            app.PlotButton.Enable = "off";
        end

        % Disable XTVariables
        function disableXTVariables (app)
            app.SensorDropDown.Enable = "off";
            app.SensorDropDownLabel.Enable = "off";
            app.ChannelAmpMaxEditField.Enable = "off";
            app.ChannelAmpMaxEditFieldLabel.Enable = "off";
            app.ChannelAmpMinEditField.Enable = "off";
            app.ChannelAmpMinEditFieldLabel.Enable = "off";
            app.MapMethodDropDown.Enable = "off";
            app.MapMethodDropDownLabel.Enable = "off";
            app.MaxModeDropDown.Enable = "off";
            app.MaxModeDropDownLabel.Enable = "off";
            app.NoofBinsSpinner.Enable = "off";
            app.NoofBinsSpinnerLabel.Enable = "off";
        end

        % Disable SMMVariables
        function disableSMMVariables (app)
            app.PX0DuraMsEditField.Enable = "off";
            app.PX0DuraMsEditFieldLabel.Enable = "off";
            app.PX1DuraMsEditField.Enable = "off";
            app.PX1DuraMsEditFieldLabel.Enable = "off";
            app.ZDelayEditField.Enable = "off";
            app.ZDelayEditFieldLabel.Enable = "off";
            app.NShiftEditField.Enable = "off";
            app.NShiftEditFieldLabel.Enable = "off";
            app.FilterWidthEditField.Enable = "off";
            app.FilterWidthEditFieldLabel.Enable = "off";
            app.FilterStdEditField.Enable = "off";
            app.FilterStdEditFieldLabel.Enable = "off";
            app.NoofEventsEditField.Enable = "off";
            app.NoofEventsEditFieldLabel.Enable = "off";
            app.NoofEventsDropDown.Enable = "off";
        end
        
        % Disable everything
        function disable (app)
            % Reset the Yes/No button for time Question in first coloumn
            app.YesCheckBoxFrequencyColumn.Value = 0;
            app.NoCheckBoxFrequencyColumn.Value = 0;

            app.disableYesNoCheckbox();
            app.disableXTBoxes();
            app.disableXTNoResultants();

            % Disable the SMM buttons if enabled
            if app.CreateSMMAllButton.Enable == "on"
                app.disableSMM();
            end
            app.disableXTVariables();
            app.disableSMMVariables();
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
                app.disable();
                app.enableYesNoCheckbox();
            catch
                app.disable();
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
                app.enableXTBoxes();

                % Disable the import times/frequency of 'no' button
                app.disableXTNoResultants();
                
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
                app.fillXtDataHolder();

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
                app.enableXTBoxes();
                app.enableXTNoResultants();

                % Disable the XT Variables
                app.disableXTVariables();
                
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
                app.fillXtDataHolder();  
            
                % Add data for the class table
                xtClassData = cell2table(app.xt_data_holder);
                app.xtDataTable1.Data = xtClassData;
    
                % Display data for Drop-Down Menu
                for i = 1 : width(app.xt_data)
                    app.XTChannelsDropDown.Items{i} = app.xt_data_holder{1,1}(i).sensor;
                end

                % Enable XT DataCell Variables
                app.enableXTVariables();
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
            app.fillXtDataHolder();  
        
            % Add data for the class table
            xtClassData = cell2table(app.xt_data_holder);
            app.xtDataTable1.Data = xtClassData;

            % Display data for Drop-Down Menu
            for i = 1 : width(app.xt_data)
                app.XTChannelsDropDown.Items{i} = app.xt_data_holder{1,1}(i).sensor;
            end

            % Enable XT DataCell Variables
            app.enableXTVariables();
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
            app.disableSMMVariables();

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
                app.fillPPDataHolder();
    
                % Display sensors in the dropdown menu
                app.PPChannelsDropDown.Items = {app.pp_data_holder{1,1}.sensor};
            end
        end

        % Button pushed function: CreateSMMAllButton
        function CreateSMMAllButtonPushed(app, event)
            app.createSMM();
        end

        % Button pushed function: PlotButton
        function PlotButtonPushed(app, event)
            app.plotSMM();
        end

        % Value changed function: SensorDropDown
        function SensorDropDownValueChanged(app, event)
            value = app.SensorDropDown.Value;
            trial = 1;
            app.sensor_index = find(strcmp(value, app.SensorDropDown.Items));

            % Set Limits for ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Limits = [app.original_xtdc.channelAmpMin(app.sensor_index, trial) app.original_xtdc.channelAmpMax(app.sensor_index, trial)];
            app.ChannelAmpMinEditField.Limits = [app.original_xtdc.channelAmpMin(app.sensor_index, trial) app.original_xtdc.channelAmpMax(app.sensor_index, trial)];
            % ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Value = app.xtdc.channelAmpMax(app.sensor_index, trial);
            app.ChannelAmpMinEditField.Value = app.xtdc.channelAmpMin(app.sensor_index, trial);
        end

        % Value changed function: ChannelAmpMaxEditField
        function ChannelAmpMaxEditFieldValueChanged(app, event)
            value = app.ChannelAmpMaxEditField.Value;
            trial = 1;

            app.xtdc.channelAmpMax(app.sensor_index, trial) = value;
        end

        % Value changed function: ChannelAmpMinEditField
        function ChannelAmpMinEditFieldValueChanged(app, event)
            value = app.ChannelAmpMinEditField.Value;
            trial = 1;

            app.xtdc.channelAmpMin(app.sensor_index, trial) = value;
        end

        % Value changed function: MapMethodDropDown
        function MapMethodDropDownValueChanged(app, event)
            value = app.MapMethodDropDown.Value;
            app.xtdc.mapMethod = value;         
        end

        % Value changed function: MaxModeDropDown
        function MaxModeDropDownValueChanged(app, event)
            value = app.MaxModeDropDown.Value;
            app.xtdc.maxMode = value;          
        end

        % Value changed function: NoofBinsSpinner
        function NoofBinsSpinnerValueChanged(app, event)
            value = app.NoofBinsSpinner.Value;
            app.xtdc.nBins = value;           
        end

        % Value changed function: PX0DuraMsEditField
        function PX0DuraMsEditFieldValueChanged(app, event)
            value = app.PX0DuraMsEditField.Value;
            app.smm.px0DuraMs = value;
        end

        % Value changed function: PX1DuraMsEditField
        function PX1DuraMsEditFieldValueChanged(app, event)
            value = app.PX1DuraMsEditField.Value;
            app.smm.px1DuraMs = value;
        end

        % Value changed function: ZDelayEditField
        function ZDelayEditFieldValueChanged(app, event)
            value = app.ZDelayEditField.Value;
            app.smm.zDelay = value;
        end

        % Value changed function: NShiftEditField
        function NShiftEditFieldValueChanged(app, event)
            value = app.NShiftEditField.Value;
            app.smm.nShift = value;
        end

        % Value changed function: FilterWidthEditField
        function FilterWidthEditFieldValueChanged(app, event)
            value = app.FilterWidthEditField.Value;
            app.smm.filterWid = value;
        end

        % Value changed function: FilterStdEditField
        function FilterStdEditFieldValueChanged(app, event)
            value = app.FilterStdEditField.Value;
            app.smm.filterStd = value;
        end

        % Value changed function: NoofEventsDropDown
        function NoofEventsDropDownValueChanged(app, event)
            value = app.NoofEventsDropDown.Value;
            pp_sensor_index = find(strcmp(value, app.NoofEventsDropDown.Items));

            app.NoofEventsEditField.Value = app.smm.nEventsUsed(pp_sensor_index, 1);
        end

        % Button pushed function: CreateSMMSelectedButton
        function CreateSMMSelectedButtonPushed(app, event)
            xt_channel = find(strcmp(app.XTChannelsDropDown.Value, app.XTChannelsDropDown.Items));
            pp_channel = find(strcmp(app.PPChannelsDropDown.Value, app.PPChannelsDropDown.Items));
            
            app.createSMM(xt_channel, pp_channel);
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
            app.GridLayout.RowHeight = {47, 300, 33, 250, 22, 37, 22, 22, 22, 22, 22, 22, 300, 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 'fit', 300, 'fit', 70};
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

            % Create XTDataLabel
            app.XTDataLabel = uilabel(app.GridLayout);
            app.XTDataLabel.HorizontalAlignment = 'center';
            app.XTDataLabel.FontSize = 14;
            app.XTDataLabel.FontWeight = 'bold';
            app.XTDataLabel.Layout.Row = 5;
            app.XTDataLabel.Layout.Column = [4 5];
            app.XTDataLabel.Text = 'XT Data';

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
            app.xtDataTable2.Layout.Column = [11 17];

            % Create xtDataTable3
            app.xtDataTable3 = uitable(app.GridLayout);
            app.xtDataTable3.ColumnName = '';
            app.xtDataTable3.RowName = {};
            app.xtDataTable3.Visible = 'off';
            app.xtDataTable3.Layout.Row = 4;
            app.xtDataTable3.Layout.Column = 18;

            % Create PPDataLabel
            app.PPDataLabel = uilabel(app.GridLayout);
            app.PPDataLabel.FontSize = 14;
            app.PPDataLabel.FontWeight = 'bold';
            app.PPDataLabel.Layout.Row = 5;
            app.PPDataLabel.Layout.Column = 16;
            app.PPDataLabel.Text = 'PP Data';

            % Create ImportPPCSVButton
            app.ImportPPCSVButton = uibutton(app.GridLayout, 'push');
            app.ImportPPCSVButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPPCSVButtonPushed, true);
            app.ImportPPCSVButton.WordWrap = 'on';
            app.ImportPPCSVButton.Layout.Row = 6;
            app.ImportPPCSVButton.Layout.Column = [15 16];
            app.ImportPPCSVButton.Text = 'Import PP CSV';

            % Create CreateSMMAllButton
            app.CreateSMMAllButton = uibutton(app.GridLayout, 'push');
            app.CreateSMMAllButton.ButtonPushedFcn = createCallbackFcn(app, @CreateSMMAllButtonPushed, true);
            app.CreateSMMAllButton.Enable = 'off';
            app.CreateSMMAllButton.Layout.Row = 11;
            app.CreateSMMAllButton.Layout.Column = 12;
            app.CreateSMMAllButton.Text = 'CreateSMM All';

            % Create PlotButton
            app.PlotButton = uibutton(app.GridLayout, 'push');
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);
            app.PlotButton.Enable = 'off';
            app.PlotButton.Layout.Row = 14;
            app.PlotButton.Layout.Column = [12 13];
            app.PlotButton.Text = 'Plot';

            % Create DiffusionPanel
            app.DiffusionPanel = uipanel(app.GridLayout);
            app.DiffusionPanel.Layout.Row = 22;
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

            % Create XTChannelsDropDownLabel
            app.XTChannelsDropDownLabel = uilabel(app.GridLayout);
            app.XTChannelsDropDownLabel.HorizontalAlignment = 'center';
            app.XTChannelsDropDownLabel.Layout.Row = 11;
            app.XTChannelsDropDownLabel.Layout.Column = [3 5];
            app.XTChannelsDropDownLabel.Text = 'XT Channels';

            % Create XTChannelsDropDown
            app.XTChannelsDropDown = uidropdown(app.GridLayout);
            app.XTChannelsDropDown.Items = {};
            app.XTChannelsDropDown.Layout.Row = 11;
            app.XTChannelsDropDown.Layout.Column = [6 9];
            app.XTChannelsDropDown.Value = {};

            % Create SelectColumnListBoxLabel
            app.SelectColumnListBoxLabel = uilabel(app.GridLayout);
            app.SelectColumnListBoxLabel.HorizontalAlignment = 'right';
            app.SelectColumnListBoxLabel.Enable = 'off';
            app.SelectColumnListBoxLabel.Layout.Row = 2;
            app.SelectColumnListBoxLabel.Layout.Column = 12;
            app.SelectColumnListBoxLabel.Text = 'Select Column';

            % Create PPChannelsDropDownLabel
            app.PPChannelsDropDownLabel = uilabel(app.GridLayout);
            app.PPChannelsDropDownLabel.Layout.Row = 11;
            app.PPChannelsDropDownLabel.Layout.Column = 16;
            app.PPChannelsDropDownLabel.Text = 'PP Channels';

            % Create PPChannelsDropDown
            app.PPChannelsDropDown = uidropdown(app.GridLayout);
            app.PPChannelsDropDown.Items = {};
            app.PPChannelsDropDown.Layout.Row = 11;
            app.PPChannelsDropDown.Layout.Column = 17;
            app.PPChannelsDropDown.Value = {};

            % Create TabGroup
            app.TabGroup = uitabgroup(app.GridLayout);
            app.TabGroup.Layout.Row = 23;
            app.TabGroup.Layout.Column = [2 17];

            % Create XTDCTab
            app.XTDCTab = uitab(app.TabGroup);
            app.XTDCTab.Title = 'XTDC';

            % Create PPDCTab
            app.PPDCTab = uitab(app.TabGroup);
            app.PPDCTab.Title = 'PPDC';

            % Create SMMTab
            app.SMMTab = uitab(app.TabGroup);
            app.SMMTab.Title = 'SMM';

            % Create MapMethodDropDownLabel
            app.MapMethodDropDownLabel = uilabel(app.GridLayout);
            app.MapMethodDropDownLabel.HorizontalAlignment = 'center';
            app.MapMethodDropDownLabel.Enable = 'off';
            app.MapMethodDropDownLabel.Layout.Row = 18;
            app.MapMethodDropDownLabel.Layout.Column = [2 3];
            app.MapMethodDropDownLabel.Text = 'Map Method';

            % Create MapMethodDropDown
            app.MapMethodDropDown = uidropdown(app.GridLayout);
            app.MapMethodDropDown.Items = {'linear', 'log', 'linearsigned', 'logsigned'};
            app.MapMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @MapMethodDropDownValueChanged, true);
            app.MapMethodDropDown.Enable = 'off';
            app.MapMethodDropDown.Layout.Row = 18;
            app.MapMethodDropDown.Layout.Column = [4 7];
            app.MapMethodDropDown.Value = 'log';

            % Create MaxModeDropDownLabel
            app.MaxModeDropDownLabel = uilabel(app.GridLayout);
            app.MaxModeDropDownLabel.HorizontalAlignment = 'center';
            app.MaxModeDropDownLabel.Enable = 'off';
            app.MaxModeDropDownLabel.Layout.Row = 19;
            app.MaxModeDropDownLabel.Layout.Column = [2 3];
            app.MaxModeDropDownLabel.Text = 'Max Mode';

            % Create MaxModeDropDown
            app.MaxModeDropDown = uidropdown(app.GridLayout);
            app.MaxModeDropDown.Items = {'pTrial', 'xTrialxSeg'};
            app.MaxModeDropDown.ValueChangedFcn = createCallbackFcn(app, @MaxModeDropDownValueChanged, true);
            app.MaxModeDropDown.Enable = 'off';
            app.MaxModeDropDown.Layout.Row = 19;
            app.MaxModeDropDown.Layout.Column = [4 7];
            app.MaxModeDropDown.Value = 'xTrialxSeg';

            % Create ChannelAmpMaxEditFieldLabel
            app.ChannelAmpMaxEditFieldLabel = uilabel(app.GridLayout);
            app.ChannelAmpMaxEditFieldLabel.HorizontalAlignment = 'center';
            app.ChannelAmpMaxEditFieldLabel.Enable = 'off';
            app.ChannelAmpMaxEditFieldLabel.Layout.Row = 16;
            app.ChannelAmpMaxEditFieldLabel.Layout.Column = [2 4];
            app.ChannelAmpMaxEditFieldLabel.Text = 'ChannelAmpMax';

            % Create ChannelAmpMaxEditField
            app.ChannelAmpMaxEditField = uieditfield(app.GridLayout, 'numeric');
            app.ChannelAmpMaxEditField.ValueChangedFcn = createCallbackFcn(app, @ChannelAmpMaxEditFieldValueChanged, true);
            app.ChannelAmpMaxEditField.Enable = 'off';
            app.ChannelAmpMaxEditField.Layout.Row = 16;
            app.ChannelAmpMaxEditField.Layout.Column = [5 7];

            % Create ChannelAmpMinEditFieldLabel
            app.ChannelAmpMinEditFieldLabel = uilabel(app.GridLayout);
            app.ChannelAmpMinEditFieldLabel.HorizontalAlignment = 'center';
            app.ChannelAmpMinEditFieldLabel.Enable = 'off';
            app.ChannelAmpMinEditFieldLabel.Layout.Row = 17;
            app.ChannelAmpMinEditFieldLabel.Layout.Column = [2 4];
            app.ChannelAmpMinEditFieldLabel.Text = 'ChannelAmpMin';

            % Create ChannelAmpMinEditField
            app.ChannelAmpMinEditField = uieditfield(app.GridLayout, 'numeric');
            app.ChannelAmpMinEditField.ValueChangedFcn = createCallbackFcn(app, @ChannelAmpMinEditFieldValueChanged, true);
            app.ChannelAmpMinEditField.Enable = 'off';
            app.ChannelAmpMinEditField.Layout.Row = 17;
            app.ChannelAmpMinEditField.Layout.Column = [5 7];

            % Create NoofBinsSpinnerLabel
            app.NoofBinsSpinnerLabel = uilabel(app.GridLayout);
            app.NoofBinsSpinnerLabel.HorizontalAlignment = 'center';
            app.NoofBinsSpinnerLabel.Enable = 'off';
            app.NoofBinsSpinnerLabel.Layout.Row = 20;
            app.NoofBinsSpinnerLabel.Layout.Column = [2 3];
            app.NoofBinsSpinnerLabel.Text = 'No. of Bins';

            % Create NoofBinsSpinner
            app.NoofBinsSpinner = uispinner(app.GridLayout);
            app.NoofBinsSpinner.Limits = [0 Inf];
            app.NoofBinsSpinner.ValueChangedFcn = createCallbackFcn(app, @NoofBinsSpinnerValueChanged, true);
            app.NoofBinsSpinner.Enable = 'off';
            app.NoofBinsSpinner.Layout.Row = 20;
            app.NoofBinsSpinner.Layout.Column = [4 7];

            % Create ZDelayEditFieldLabel
            app.ZDelayEditFieldLabel = uilabel(app.GridLayout);
            app.ZDelayEditFieldLabel.HorizontalAlignment = 'center';
            app.ZDelayEditFieldLabel.Enable = 'off';
            app.ZDelayEditFieldLabel.Layout.Row = 17;
            app.ZDelayEditFieldLabel.Layout.Column = [14 15];
            app.ZDelayEditFieldLabel.Text = 'Z Delay';

            % Create ZDelayEditField
            app.ZDelayEditField = uieditfield(app.GridLayout, 'numeric');
            app.ZDelayEditField.Limits = [0 Inf];
            app.ZDelayEditField.ValueChangedFcn = createCallbackFcn(app, @ZDelayEditFieldValueChanged, true);
            app.ZDelayEditField.Enable = 'off';
            app.ZDelayEditField.Layout.Row = 17;
            app.ZDelayEditField.Layout.Column = 16;

            % Create NShiftEditFieldLabel
            app.NShiftEditFieldLabel = uilabel(app.GridLayout);
            app.NShiftEditFieldLabel.HorizontalAlignment = 'center';
            app.NShiftEditFieldLabel.Enable = 'off';
            app.NShiftEditFieldLabel.Layout.Row = 18;
            app.NShiftEditFieldLabel.Layout.Column = [14 15];
            app.NShiftEditFieldLabel.Text = 'N Shift';

            % Create NShiftEditField
            app.NShiftEditField = uieditfield(app.GridLayout, 'numeric');
            app.NShiftEditField.Limits = [0 Inf];
            app.NShiftEditField.ValueChangedFcn = createCallbackFcn(app, @NShiftEditFieldValueChanged, true);
            app.NShiftEditField.Enable = 'off';
            app.NShiftEditField.Layout.Row = 18;
            app.NShiftEditField.Layout.Column = 16;

            % Create FilterWidthEditFieldLabel
            app.FilterWidthEditFieldLabel = uilabel(app.GridLayout);
            app.FilterWidthEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterWidthEditFieldLabel.Enable = 'off';
            app.FilterWidthEditFieldLabel.Layout.Row = 19;
            app.FilterWidthEditFieldLabel.Layout.Column = [14 15];
            app.FilterWidthEditFieldLabel.Text = 'Filter Width';

            % Create FilterWidthEditField
            app.FilterWidthEditField = uieditfield(app.GridLayout, 'numeric');
            app.FilterWidthEditField.Limits = [0 Inf];
            app.FilterWidthEditField.ValueChangedFcn = createCallbackFcn(app, @FilterWidthEditFieldValueChanged, true);
            app.FilterWidthEditField.Enable = 'off';
            app.FilterWidthEditField.Layout.Row = 19;
            app.FilterWidthEditField.Layout.Column = 16;

            % Create FilterStdEditFieldLabel
            app.FilterStdEditFieldLabel = uilabel(app.GridLayout);
            app.FilterStdEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterStdEditFieldLabel.Enable = 'off';
            app.FilterStdEditFieldLabel.Layout.Row = 20;
            app.FilterStdEditFieldLabel.Layout.Column = [14 15];
            app.FilterStdEditFieldLabel.Text = 'Filter Std';

            % Create FilterStdEditField
            app.FilterStdEditField = uieditfield(app.GridLayout, 'numeric');
            app.FilterStdEditField.Limits = [0 Inf];
            app.FilterStdEditField.ValueChangedFcn = createCallbackFcn(app, @FilterStdEditFieldValueChanged, true);
            app.FilterStdEditField.Enable = 'off';
            app.FilterStdEditField.Layout.Row = 20;
            app.FilterStdEditField.Layout.Column = 16;

            % Create PX0DuraMsEditFieldLabel
            app.PX0DuraMsEditFieldLabel = uilabel(app.GridLayout);
            app.PX0DuraMsEditFieldLabel.HorizontalAlignment = 'center';
            app.PX0DuraMsEditFieldLabel.Enable = 'off';
            app.PX0DuraMsEditFieldLabel.Layout.Row = 15;
            app.PX0DuraMsEditFieldLabel.Layout.Column = [14 15];
            app.PX0DuraMsEditFieldLabel.Text = 'PX0 DuraMs';

            % Create PX0DuraMsEditField
            app.PX0DuraMsEditField = uieditfield(app.GridLayout, 'numeric');
            app.PX0DuraMsEditField.Limits = [-Inf 0];
            app.PX0DuraMsEditField.ValueChangedFcn = createCallbackFcn(app, @PX0DuraMsEditFieldValueChanged, true);
            app.PX0DuraMsEditField.Enable = 'off';
            app.PX0DuraMsEditField.Layout.Row = 15;
            app.PX0DuraMsEditField.Layout.Column = 16;

            % Create PX1DuraMsEditFieldLabel
            app.PX1DuraMsEditFieldLabel = uilabel(app.GridLayout);
            app.PX1DuraMsEditFieldLabel.HorizontalAlignment = 'center';
            app.PX1DuraMsEditFieldLabel.Enable = 'off';
            app.PX1DuraMsEditFieldLabel.Layout.Row = 16;
            app.PX1DuraMsEditFieldLabel.Layout.Column = [14 15];
            app.PX1DuraMsEditFieldLabel.Text = 'PX1 DuraMs';

            % Create PX1DuraMsEditField
            app.PX1DuraMsEditField = uieditfield(app.GridLayout, 'numeric');
            app.PX1DuraMsEditField.Limits = [0 Inf];
            app.PX1DuraMsEditField.ValueChangedFcn = createCallbackFcn(app, @PX1DuraMsEditFieldValueChanged, true);
            app.PX1DuraMsEditField.Enable = 'off';
            app.PX1DuraMsEditField.Layout.Row = 16;
            app.PX1DuraMsEditField.Layout.Column = 16;

            % Create NoofEventsEditFieldLabel
            app.NoofEventsEditFieldLabel = uilabel(app.GridLayout);
            app.NoofEventsEditFieldLabel.HorizontalAlignment = 'center';
            app.NoofEventsEditFieldLabel.Enable = 'off';
            app.NoofEventsEditFieldLabel.Layout.Row = 21;
            app.NoofEventsEditFieldLabel.Layout.Column = [14 15];
            app.NoofEventsEditFieldLabel.Text = 'No of Events';

            % Create NoofEventsEditField
            app.NoofEventsEditField = uieditfield(app.GridLayout, 'numeric');
            app.NoofEventsEditField.Limits = [0 Inf];
            app.NoofEventsEditField.Editable = 'off';
            app.NoofEventsEditField.Enable = 'off';
            app.NoofEventsEditField.Layout.Row = 21;
            app.NoofEventsEditField.Layout.Column = 16;

            % Create CreateSMMSelectedButton
            app.CreateSMMSelectedButton = uibutton(app.GridLayout, 'push');
            app.CreateSMMSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @CreateSMMSelectedButtonPushed, true);
            app.CreateSMMSelectedButton.Enable = 'off';
            app.CreateSMMSelectedButton.Layout.Row = 11;
            app.CreateSMMSelectedButton.Layout.Column = 13;
            app.CreateSMMSelectedButton.Text = 'CreateSMM Selected';

            % Create XTDCLabel
            app.XTDCLabel = uilabel(app.GridLayout);
            app.XTDCLabel.HorizontalAlignment = 'center';
            app.XTDCLabel.Layout.Row = 14;
            app.XTDCLabel.Layout.Column = [2 7];
            app.XTDCLabel.Text = 'XTDC';

            % Create SMMLabel
            app.SMMLabel = uilabel(app.GridLayout);
            app.SMMLabel.HorizontalAlignment = 'center';
            app.SMMLabel.Layout.Row = 14;
            app.SMMLabel.Layout.Column = [14 16];
            app.SMMLabel.Text = 'SMM';

            % Create SensorDropDownLabel
            app.SensorDropDownLabel = uilabel(app.GridLayout);
            app.SensorDropDownLabel.HorizontalAlignment = 'center';
            app.SensorDropDownLabel.Enable = 'off';
            app.SensorDropDownLabel.Layout.Row = 15;
            app.SensorDropDownLabel.Layout.Column = [2 3];
            app.SensorDropDownLabel.Text = 'Sensor';

            % Create SensorDropDown
            app.SensorDropDown = uidropdown(app.GridLayout);
            app.SensorDropDown.Items = {};
            app.SensorDropDown.ValueChangedFcn = createCallbackFcn(app, @SensorDropDownValueChanged, true);
            app.SensorDropDown.Enable = 'off';
            app.SensorDropDown.Layout.Row = 15;
            app.SensorDropDown.Layout.Column = [4 7];
            app.SensorDropDown.Value = {};

            % Create DefaultLabelMapMethod
            app.DefaultLabelMapMethod = uilabel(app.GridLayout);
            app.DefaultLabelMapMethod.HorizontalAlignment = 'center';
            app.DefaultLabelMapMethod.Layout.Row = 18;
            app.DefaultLabelMapMethod.Layout.Column = 9;
            app.DefaultLabelMapMethod.Text = '-';

            % Create DefaultLabelMaxMode
            app.DefaultLabelMaxMode = uilabel(app.GridLayout);
            app.DefaultLabelMaxMode.HorizontalAlignment = 'center';
            app.DefaultLabelMaxMode.Layout.Row = 19;
            app.DefaultLabelMaxMode.Layout.Column = 9;
            app.DefaultLabelMaxMode.Text = '-';

            % Create DefaultLabelNoOfBins
            app.DefaultLabelNoOfBins = uilabel(app.GridLayout);
            app.DefaultLabelNoOfBins.HorizontalAlignment = 'center';
            app.DefaultLabelNoOfBins.Layout.Row = 20;
            app.DefaultLabelNoOfBins.Layout.Column = 9;
            app.DefaultLabelNoOfBins.Text = '-';

            % Create DefaultLabelXTDC
            app.DefaultLabelXTDC = uilabel(app.GridLayout);
            app.DefaultLabelXTDC.HorizontalAlignment = 'center';
            app.DefaultLabelXTDC.Layout.Row = 14;
            app.DefaultLabelXTDC.Layout.Column = 9;
            app.DefaultLabelXTDC.Text = 'Default';

            % Create DefaultLabelPX0
            app.DefaultLabelPX0 = uilabel(app.GridLayout);
            app.DefaultLabelPX0.HorizontalAlignment = 'center';
            app.DefaultLabelPX0.Layout.Row = 15;
            app.DefaultLabelPX0.Layout.Column = 17;
            app.DefaultLabelPX0.Text = '-';

            % Create DefaultLabelPX1
            app.DefaultLabelPX1 = uilabel(app.GridLayout);
            app.DefaultLabelPX1.HorizontalAlignment = 'center';
            app.DefaultLabelPX1.Layout.Row = 16;
            app.DefaultLabelPX1.Layout.Column = 17;
            app.DefaultLabelPX1.Text = '-';

            % Create DefaultLabelZDelay
            app.DefaultLabelZDelay = uilabel(app.GridLayout);
            app.DefaultLabelZDelay.HorizontalAlignment = 'center';
            app.DefaultLabelZDelay.Layout.Row = 17;
            app.DefaultLabelZDelay.Layout.Column = 17;
            app.DefaultLabelZDelay.Text = '-';

            % Create DefaultLabelNShift
            app.DefaultLabelNShift = uilabel(app.GridLayout);
            app.DefaultLabelNShift.HorizontalAlignment = 'center';
            app.DefaultLabelNShift.Layout.Row = 18;
            app.DefaultLabelNShift.Layout.Column = 17;
            app.DefaultLabelNShift.Text = '-';

            % Create DefaultLabelFilterWidth
            app.DefaultLabelFilterWidth = uilabel(app.GridLayout);
            app.DefaultLabelFilterWidth.HorizontalAlignment = 'center';
            app.DefaultLabelFilterWidth.Layout.Row = 19;
            app.DefaultLabelFilterWidth.Layout.Column = 17;
            app.DefaultLabelFilterWidth.Text = '-';

            % Create DefaultLabelFilterStd
            app.DefaultLabelFilterStd = uilabel(app.GridLayout);
            app.DefaultLabelFilterStd.HorizontalAlignment = 'center';
            app.DefaultLabelFilterStd.Layout.Row = 20;
            app.DefaultLabelFilterStd.Layout.Column = 17;
            app.DefaultLabelFilterStd.Text = '-';

            % Create DefaultLabelPPDC
            app.DefaultLabelPPDC = uilabel(app.GridLayout);
            app.DefaultLabelPPDC.HorizontalAlignment = 'center';
            app.DefaultLabelPPDC.Layout.Row = 14;
            app.DefaultLabelPPDC.Layout.Column = 17;
            app.DefaultLabelPPDC.Text = 'Default';

            % Create NoofEventsDropDown
            app.NoofEventsDropDown = uidropdown(app.GridLayout);
            app.NoofEventsDropDown.Items = {};
            app.NoofEventsDropDown.ValueChangedFcn = createCallbackFcn(app, @NoofEventsDropDownValueChanged, true);
            app.NoofEventsDropDown.Enable = 'off';
            app.NoofEventsDropDown.Layout.Row = 21;
            app.NoofEventsDropDown.Layout.Column = 17;
            app.NoofEventsDropDown.Value = {};

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