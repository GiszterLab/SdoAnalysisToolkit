classdef app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        XTrialXSegWarningLabel       matlab.ui.control.Label
        DiffusionPanel               matlab.ui.container.Panel
        StirpdPanel                  matlab.ui.container.Panel
        MatrixPanel                  matlab.ui.container.Panel
        NoofEventsDropDown           matlab.ui.control.DropDown
        NoofEventsEditField          matlab.ui.control.NumericEditField
        NoofEventsEditFieldLabel     matlab.ui.control.Label
        CreateSMMAllButton           matlab.ui.control.Button
        DefaultLabelFilterStd        matlab.ui.control.Label
        FilterStdEditField           matlab.ui.control.NumericEditField
        FilterStdEditFieldLabel      matlab.ui.control.Label
        CreateSMMSelectedButton      matlab.ui.control.Button
        DefaultLabelFilterWidth      matlab.ui.control.Label
        FilterWidthEditField         matlab.ui.control.NumericEditField
        FilterWidthEditFieldLabel    matlab.ui.control.Label
        DefaultLabelNShift           matlab.ui.control.Label
        NShiftEditField              matlab.ui.control.NumericEditField
        NShiftEditFieldLabel         matlab.ui.control.Label
        SMMPlotButton                matlab.ui.control.Button
        DefaultLabelZDelay           matlab.ui.control.Label
        ZDelayEditField              matlab.ui.control.NumericEditField
        ZDelayEditFieldLabel         matlab.ui.control.Label
        PPChannelsDropDown           matlab.ui.control.DropDown
        PPChannelsDropDownLabel      matlab.ui.control.Label
        PPChannelsBeforeSMMListBox   matlab.ui.control.ListBox
        PPChannelsLabel              matlab.ui.control.Label
        DefaultLabelPX1              matlab.ui.control.Label
        PX1DuraMsEditField           matlab.ui.control.NumericEditField
        PX1DuraMsEditFieldLabel      matlab.ui.control.Label
        XTChannelsDropDown           matlab.ui.control.DropDown
        XTChannelsDropDownLabel      matlab.ui.control.Label
        DefaultLabelPX0              matlab.ui.control.Label
        PX0DuraMsEditField           matlab.ui.control.NumericEditField
        PX0DuraMsEditFieldLabel      matlab.ui.control.Label
        DefaultLabelSMM              matlab.ui.control.Label
        SMMLabel                     matlab.ui.control.Label
        EMGChannelsBeforeSMMListBox  matlab.ui.control.ListBox
        EMGChannelsLabel             matlab.ui.control.Label
        PX0PX1Panel                  matlab.ui.container.Panel
        SDOMultiMatLabel             matlab.ui.control.Label
        HTMLLineBreak2               matlab.ui.control.HTML
        XTDCPlotHistograms           matlab.ui.control.Button
        XTDCDataFieldButtonGroup     matlab.ui.container.ButtonGroup
        XTDCFilteredButton           matlab.ui.control.ToggleButton
        XTDCRawButton                matlab.ui.control.ToggleButton
        DefaultLabelNoOfBins         matlab.ui.control.Label
        NoofBinsSpinner              matlab.ui.control.Spinner
        NoofBinsSpinnerLabel         matlab.ui.control.Label
        DefaultLabelMaxMode          matlab.ui.control.Label
        MaxModeDropDown              matlab.ui.control.DropDown
        MaxModeDropDownLabel         matlab.ui.control.Label
        DefaultLabelMapMethod        matlab.ui.control.Label
        MapMethodDropDown            matlab.ui.control.DropDown
        MapMethodDropDownLabel       matlab.ui.control.Label
        XTDCChannelsListBox          matlab.ui.control.ListBox
        EMGChannelsLabel_2           matlab.ui.control.Label
        DefaultLabelChannelAmpMin    matlab.ui.control.Label
        ChannelAmpMinEditField       matlab.ui.control.NumericEditField
        ChannelAmpMinEditFieldLabel  matlab.ui.control.Label
        DefaultLabelChannelAmpMax    matlab.ui.control.Label
        ChannelAmpMaxEditField       matlab.ui.control.NumericEditField
        ChannelAmpMaxEditFieldLabel  matlab.ui.control.Label
        TrialDropDown                matlab.ui.control.DropDown
        TrialDropDownLabel           matlab.ui.control.Label
        SensorDropDown               matlab.ui.control.DropDown
        SensorDropDownLabel          matlab.ui.control.Label
        XTDCTrialsListBox            matlab.ui.control.ListBox
        EMGTrialsLabel               matlab.ui.control.Label
        DefaultLabelXTDC             matlab.ui.control.Label
        XTDCLabel                    matlab.ui.control.Label
        XTDCHistogramsLabel          matlab.ui.control.Label
        HTMLLineBreak                matlab.ui.control.HTML
        PPButton                     matlab.ui.control.Button
        PPChannelsListBox            matlab.ui.control.ListBox
        PPChannelsLabel_2            matlab.ui.control.Label
        PPTrialsListBox              matlab.ui.control.ListBox
        PPTrialsLabel                matlab.ui.control.Label
        ISIPanel                     matlab.ui.container.Panel
        ImportPPDCButton             matlab.ui.control.Button
        ExportPPDCButton             matlab.ui.control.Button
        ImportPPCustButton           matlab.ui.control.Button
        ImportPPTrevorButton         matlab.ui.control.Button
        PPDataLabel                  matlab.ui.control.Label
        OriginalXTDCPlotButton       matlab.ui.control.Button
        SpikesRatePanel              matlab.ui.container.Panel
        OriginalXTDCDataFieldButtonGroup  matlab.ui.container.ButtonGroup
        OriginalXTDCFilteredButton   matlab.ui.control.ToggleButton
        OriginalXTDCRawButton        matlab.ui.control.ToggleButton
        OriginalXTDCChannelsListBox  matlab.ui.control.ListBox
        OriginalEMGChannelsLabel     matlab.ui.control.Label
        OriginalXTDCTrialsListBox    matlab.ui.control.ListBox
        OriginalEMGTrialsLabel       matlab.ui.control.Label
        ImportTimesButton            matlab.ui.control.Button
        ORLabel                      matlab.ui.control.Label
        FrequencyEditField           matlab.ui.control.NumericEditField
        FrequencyEditFieldLabel      matlab.ui.control.Label
        ImportXTDCButton             matlab.ui.control.Button
        NoCheckBoxFrequencyColumn    matlab.ui.control.CheckBox
        YesCheckBoxFrequencyColumn   matlab.ui.control.CheckBox
        ExportXTDCButton             matlab.ui.control.Button
        ImportEMGCustButton          matlab.ui.control.Button
        EMGPanel                     matlab.ui.container.Panel
        CustomImportQuestion         matlab.ui.control.Label
        ImportEMGTrevorButton        matlab.ui.control.Button
        EMGDataLabel                 matlab.ui.control.Label
        VariableViewingLabel         matlab.ui.control.Label
        RawEMGHistogram              matlab.ui.control.UIAxes
        StateEMGHistogram            matlab.ui.control.UIAxes
    end

    
    properties (Access = private)    

        %% Custom Cells
        xt_cell % (cell) 
        pp_cell % (cell)

        %% EMG
        xt_frequency % Frequency (Might be an int)

        %% DataCells
        xtdc % Datacell for Time Series
        original_xtdc % Original XT DataCell
        ppdc % Datacell for Point Process
        original_ppdc % Original PP DataCell        
        smm % SDO Multimat Time Series
        original_smm % Original SMM Data
                
        %% Others
        trial_index % Index (Used in changing maximum and minimum value for XTDC)
        sensor_index % Index (Used in changing maximum and minimum value for XTDC)

        emg_original_listbox_trial_index % Trial Index (used for plotting EMGs)
        emg_original_listbox_channel_index % Channel Index (used for plotting EMGs)

        emg_listbox_trial_index % Trial Index (Used for plotting histograms)
        emg_listbox_channel_index % Channel Index (Used for plotting histograms)
       
        pp_listbox_trial_index % Trial Index (Used for plotting spike rates and ISIs)
        pp_listbox_channel_index % Channel Index (Used for plotting EMGs and state histograms)
    end
    
    methods (Access = private)
        %% Functions to create SMM and plot SMM

        % Create SMM object and compute it with filled XT datacell object
        % and PP datacell object
        function createSMM(app, xt_index, pp_index)
            % Initialize the SMM object
            app.smm = sdoMultiMat();
            % Always discretize after creating app.smm
            app.xtdc.discretize();
            % Create a indeterminate progress bar while computing SMM
            d = uiprogressdlg(app.UIFigure,'Title','Computing SMM',...
            'Indeterminate','on');
            if nargin == 1
                    app.smm.compute(app.xtdc, app.ppdc);
                    % app.XTChannelsDropDown.Items = app.xt_cell{1,1};
                    app.XTChannelsDropDown.Items = app.xtdc.sensor;
                    % app.PPChannelsDropDown.Items = app.pp_cell{1,1}(:,1);
                    app.PPChannelsDropDown.Items = app.ppdc.sensor;
            elseif nargin == 3
                app.smm.compute(app.xtdc, app.ppdc, xt_index, pp_index);
                app.XTChannelsDropDown.Items = app.xtdc.sensor(xt_index);
                app.PPChannelsDropDown.Items = app.ppdc.sensor(pp_index);
            end
            close(d);

            % % Store the original SMM Data
            % app.original_smm = copy(app.smm);

            % Enable the plot button for SMM
            app.enablePlotSMM();
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

            % % Plot all the smm plots
            % app.smm.plot(xt_column_number, pp_column_number);
            % % Find the third plot and copy it to UIPanel
            % figures = findobj('type', 'figure');
            % desired_figure_number = numel(figures) - 2;
            % a = figures(desired_figure_number);
            % copyobj(a.Children, app.DiffusionPanel);
            % % Close the figure after copying desired plot
            % close(figures);

            SAT.plot.plotSplitSymmetrySDO(app.smm.sdoStruct, xt_column_number, pp_column_number);
            fig = gcf;
            copyobj(fig.Children, app.DiffusionPanel);
            % Close the figure after copying
            close(fig)
        end

        %% Displaying and Updating DataCell Variables
        
        % Fill Trials' and Sensors' values in EMG list boxes for plotting
        function fillEMGListBoxes (app)
            % Get Trials
            trial_cell = cell(1, app.original_xtdc.nTrials);
            for i = 1 : length(trial_cell)
                trial_cell{i} = num2str(i);
            end

            % Fill in the values
            app.XTDCTrialsListBox.Items = trial_cell; 
            app.XTDCChannelsListBox.Items = app.original_xtdc.sensor;
            app.EMGChannelsBeforeSMMListBox.Items = app.original_xtdc.sensor;
            app.OriginalXTDCTrialsListBox.Items = trial_cell;
            app.OriginalXTDCChannelsListBox.Items = app.original_xtdc.sensor;
        end

        % Fill Trials' and Sensors' values in EMG list boxes for plotting
        function fillPPListBoxes (app)
            % Get Trials
            trial_cell = cell(1, app.ppdc.nTrials);
            for i = 1 : length(trial_cell)
                trial_cell{i} = num2str(i);
            end

            % Fill in the values
            app.PPTrialsListBox.Items = trial_cell;
            if ~isempty(app.ppdc)
                % app.PPChannelsListBox.Items = app.pp_cell{1,1}(:,1)';
                % app.PPChannelsBeforeSMMListBox.Items = app.pp_cell{1,1}(:,1)';
                app.PPChannelsListBox.Items = app.ppdc.sensor;
                app.PPChannelsBeforeSMMListBox.Items = app.ppdc.sensor;
            end
        end

        
        % Fill XTDC Values
        function fillXTVariable (app)
            % Sensors
            app.SensorDropDown.Items = app.original_xtdc.sensor;
            app.SensorDropDown.Value = app.SensorDropDown.Items{1};
            app.sensor_index = find(strcmp(app.SensorDropDown.Value, app.SensorDropDown.Items));

            % Trials
            trial_cell = cell(1, app.original_xtdc.nTrials);
            for i = 1 : length(trial_cell)
                trial_cell{i} = num2str(i);
            end
            app.TrialDropDown.Items = trial_cell;
            app.TrialDropDown.Value = app.TrialDropDown.Items{1};
            app.trial_index = find(strcmp(app.TrialDropDown.Value, app.TrialDropDown.Items));
            
            % Set Limits for ChannelAmpMax and ChannelAmpMin
            % app.ChannelAmpMaxEditField.Limits = [app.original_xtdc.channelAmpMin(1,1) app.original_xtdc.channelAmpMax(1,1)];
            % app.ChannelAmpMinEditField.Limits = [app.original_xtdc.channelAmpMin(1,1) app.original_xtdc.channelAmpMax(1,1)];
            app.ChannelAmpMaxEditField.Limits = [app.original_xtdc.channelAmpMin(1,1), inf];
            app.ChannelAmpMinEditField.Limits = [-inf, app.original_xtdc.channelAmpMax(1,1)];
            % ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Value = app.original_xtdc.channelAmpMax(1,1);
            app.ChannelAmpMinEditField.Value = app.original_xtdc.channelAmpMin(1,1);

            % Map Method and Max Mode list is manually inserted
            % drop down menu
            app.MapMethodDropDown.Value = app.original_xtdc.mapMethod;
            app.MaxModeDropDown.Value = app.original_xtdc.maxMode;
            if strcmpi(app.xtdc.maxMode, 'xTrialxSeg')
                app.enableXTrialXSegWarning();
            else
                app.disableXTrialXSegWarning();
            end

            % No. of Bins
            app.NoofBinsSpinner.Value = app.original_xtdc.nBins;

            % Default Label Values
            app.DefaultLabelChannelAmpMax.Text = string(app.original_xtdc.channelAmpMax(1,1));
            app.DefaultLabelChannelAmpMin.Text = string(app.original_xtdc.channelAmpMin(1,1));
            app.DefaultLabelMapMethod.Text = app.original_xtdc.mapMethod;
            app.DefaultLabelMaxMode.Text = app.original_xtdc.maxMode;
            app.DefaultLabelNoOfBins.Text = string(app.original_xtdc.nBins);

            % Check raw or envelope for plotting EMGs
            if strcmpi(strip(app.original_xtdc.dataField), 'raw')
                app.OriginalXTDCRawButton.Value = true;
            elseif strcmpi(strip(app.original_xtdc.dataField), 'envelope')
                app.OriginalXTDCFilteredButton.Value = true;
            end
            % Check raw or envelope for plotting EMG histogram
            if strcmpi(strip(app.xtdc.dataField), 'raw')
                app.XTDCRawButton.Value = true;
            elseif strcmpi(strip(app.xtdc.dataField), 'envelope')
                app.XTDCFilteredButton.Value = true;
            end 
        end

        % Fill SMM Values
        function fillSMMVariable (app)
            % % px0DuraMs and px1DuraMs
            % app.PX0DuraMsEditField.Value = app.original_smm.px0DuraMs;
            % app.PX1DuraMsEditField.Value = app.original_smm.px1DuraMs;
            % 
            % % zDelay and nShift
            % app.ZDelayEditField.Value = app.original_smm.zDelay;
            % app.NShiftEditField.Value = app.original_smm.nShift;
            % 
            % % Filter Width and filterStd
            % app.FilterWidthEditField.Value = app.original_smm.filterWid;
            % app.FilterStdEditField.Value = app.original_smm.filterStd;
            % 
            % % No. of events used depending on sensors
            % app.NoofEventsEditField.Value = app.original_smm.nEventsUsed(1);
            % app.NoofEventsDropDown.Items = app.original_smm.sdoStruct.neuronNames;
            % % Always show the top option (This is useful when the user
            % % decides to create another smm)
            % app.NoofEventsDropDown.Value = app.NoofEventsDropDown.Items{1};

            % % Default Label Values
            % app.DefaultLabelPX0.Text = string(app.original_smm.px0DuraMs);
            % app.DefaultLabelPX1.Text = string(app.original_smm.px1DuraMs);
            % app.DefaultLabelZDelay.Text = string(app.original_smm.zDelay);
            % app.DefaultLabelNShift.Text = string(app.original_smm.nShift);
            % app.DefaultLabelFilterWidth.Text = string(app.original_smm.filterWid);
            % app.DefaultLabelFilterStd.Text = string(app.original_smm.filterStd);

            % px0DuraMs and px1DuraMs
            app.PX0DuraMsEditField.Value = app.smm.px0DuraMs;
            app.PX1DuraMsEditField.Value = app.smm.px1DuraMs;

            % zDelay and nShift
            app.ZDelayEditField.Value = app.smm.zDelay;
            app.NShiftEditField.Value = app.smm.nShift;

            % Filter Width and filterStd
            app.FilterWidthEditField.Value = app.smm.filterWid;
            app.FilterStdEditField.Value = app.smm.filterStd;

            % No. of events used depending on sensors
            app.NoofEventsEditField.Value = app.smm.nEventsUsed(1);
            app.NoofEventsDropDown.Items = app.smm.sdoStruct.neuronNames;
            % Always show the top option (This is useful when the user
            % decides to create another smm)
            app.NoofEventsDropDown.Value = app.NoofEventsDropDown.Items{1};
        end 

        %% Interactivity

        % Enable Yes/No Checkbox
        function enableYesNoCheckbox (app)
            app.CustomImportQuestion.Enable = "on";
            app.CustomImportQuestion.Visible = "on";
            app.YesCheckBoxFrequencyColumn.Enable = "on";
            app.YesCheckBoxFrequencyColumn.Visible = "on";
            app.NoCheckBoxFrequencyColumn.Enable = "on";
            app.NoCheckBoxFrequencyColumn.Visible = "on";
        end

        % Enable the import times/frequency of 'no' button of XTData
        function enableXTNoResultants (app)
            app.ImportTimesButton.Visible = "on";
            app.FrequencyEditField.Visible = "on";
            app.FrequencyEditFieldLabel.Visible = "on";
            app.ORLabel.Visible = "on";
        end
        
        % Enable createSMM button
        % This depends on whether both XTdata and PPdata exist.
        function enableCreateSMM (app)
            yes_check_box = app.YesCheckBoxFrequencyColumn.Value;
            no_check_box = app.NoCheckBoxFrequencyColumn.Value;
            % if (yes_check_box || no_check_box) && ~isempty(app.pp_raw_data)
            if ((yes_check_box || no_check_box) && ~isempty(app.ppdc)) || (~isempty(app.xtdc) && ~isempty(app.ppdc))
                app.CreateSMMAllButton.Enable = "on";
                app.CreateSMMSelectedButton.Enable = "on";
            end
        end

        % Enable the plot button for SMM
        % This depends on whether SMM object is created
        function enablePlotSMM (app)
            if app.CreateSMMAllButton.Enable == "on" && ~isempty(app.smm)
                app.SMMPlotButton.Enable = "on";
                app.XTChannelsDropDown.Enable = "on";
                app.XTChannelsDropDownLabel.Enable = "on";
                app.PPChannelsDropDown.Enable = "on";
                app.PPChannelsDropDownLabel.Enable = "on";
            end
        end

        % Enable the listboxes for EMG
        % Enable them after creating XTDC
        function enableXTListBoxes (app)
            % Original XTDC
            app.OriginalEMGTrialsLabel.Enable = "on";
            app.OriginalXTDCTrialsListBox.Enable = "on";
            app.OriginalEMGChannelsLabel.Enable = "on";
            app.OriginalXTDCChannelsListBox.Enable = "on";
            app.OriginalXTDCDataFieldButtonGroup.Enable = "on";
            app.OriginalXTDCRawButton.Enable = "on";
            app.OriginalXTDCFilteredButton.Enable = "on";
            % Original XTDC Plot Button
            app.OriginalXTDCPlotButton.Enable = "on";

            % XTDC
            app.EMGTrialsLabel.Enable = "on";
            app.XTDCTrialsListBox.Enable = "on";
            app.EMGChannelsLabel_2.Enable = "on";
            app.XTDCChannelsListBox.Enable = "on";         
            app.EMGChannelsBeforeSMMListBox.Enable = "on";
            app.EMGChannelsLabel.Enable = "on"; % Weird! I cannot change this to 
                                                % 'EMGChannelsBeforeSMMlistBoxLabel'
            app.XTDCDataFieldButtonGroup.Enable = "on";
            app.XTDCRawButton.Enable = "on";
            app.XTDCFilteredButton.Enable = "on";         
            % Plot Button                                    
            app.XTDCPlotHistograms.Enable = "on";
        end

        % Enable the listboxes for PP
        % Enable them after creating PPDC
        function enablePPListBoxes (app)
            app.PPTrialsLabel.Enable = "on";
            app.PPTrialsListBox.Enable = "on";
            app.PPChannelsLabel_2.Enable = "on";
            app.PPChannelsListBox.Enable = "on";
            app.PPChannelsBeforeSMMListBox.Enable = "on";
            app.PPChannelsLabel.Enable = "on"; % Weird! I cannot change this to 
                                               % 'PPChannelsBeforeSMMlistBoxLabel'
            
            % Plot Button
            app.PPButton.Enable = "on";

            % Enable Exporting PPDC to Matlab Workspace
            app.enableExportPPDC();
        end

        % Warning when user selects 'xTrialxSeg' and change maxAmp and
        % minAmp
        function enableXTrialXSegWarning (app)
            app.XTrialXSegWarningLabel.Visible = "on";
            app.XTrialXSegWarningLabel.Enable = "on";
        end

        % Enable XTVariables
        function enableXTVariables (app)
            % Enable the main 'XTDC' label and 'Default' label
            app.XTDCLabel.Enable = "on";
            app.DefaultLabelXTDC.Enable = "on";

            % Enable all variables for XTDC
            app.SensorDropDown.Enable = "on";
            app.SensorDropDownLabel.Enable = "on";
            app.TrialDropDown.Enable = "on";
            app.TrialDropDownLabel.Enable = "on";
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

            % Enable ListBoxes for XTDC
            app.enableXTListBoxes();

            % Enable Exporting XTDC to Matlab Workspace
            app.enableExportXTDC();
        end

        % Enable SMMVariables
        function enableSMMVariables (app)
            % Enable Labels
            % Enable the main 'SMM' label and 'Default' label
            app.SMMLabel.Enable = "on";
            app.DefaultLabelSMM.Enable = "on";
            % Enable SMM default SMM variables label
            app.DefaultLabelPX0.Enable = "on";
            app.DefaultLabelPX1.Enable = "on";
            app.DefaultLabelZDelay.Enable = "on";
            app.DefaultLabelNShift.Enable = "on";
            app.DefaultLabelFilterWidth.Enable = "on";
            app.DefaultLabelFilterStd.Enable = "on";


            % Enable all variables for SMM
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

            % Enable PX0PX1 Panel
            app.PX0PX1Panel.Enable = "on";
        end

        function enableExportXTDC (app)
            app.ExportXTDCButton.Enable = "on";
        end
        function enableExportPPDC (app)
            app.ExportPPDCButton.Enable = "on";
        end
    
        % Disable Yes/No Checkbox
        function disableYesNoCheckbox (app)
            app.CustomImportQuestion.Enable = "off";
            app.CustomImportQuestion.Visible = "off";
            app.YesCheckBoxFrequencyColumn.Enable = "off";
            app.YesCheckBoxFrequencyColumn.Visible = "off";
            app.NoCheckBoxFrequencyColumn.Enable = "off";
            app.NoCheckBoxFrequencyColumn.Visible = "off";
        end

        % Disable the import times/frequency of 'no' button of XTData
        function disableXTNoResultants (app)
            app.ImportTimesButton.Visible = "off";
            app.FrequencyEditField.Visible = "off";
            app.FrequencyEditFieldLabel.Visible = "off";
            app.FrequencyEditField.Value = 0;
            app.ORLabel.Visible = "off";
        end

        % Disable plotting SMM
        function disablePlotSMM (app)
            app.XTChannelsDropDown.Enable = "off";
            app.XTChannelsDropDownLabel.Enable = "off";
            app.PPChannelsDropDown.Enable = "off";
            app.PPChannelsDropDownLabel.Enable = "off";
            app.SMMPlotButton.Enable = "off";
        end

        % Disable the buttons for creating and plotting SMM
        function disableSMM (app)
            app.CreateSMMAllButton.Enable = "off";
            app.CreateSMMSelectedButton.Enable = "off";
            app.diablePlotSMM();
            
        end

        % Disable the listboxes for EMG
        % Disable them after creating XTDC
        function disableXTListBoxes (app)
            % Original XTDC
            app.OriginalEMGTrialsLabel.Enable = "off";
            app.OriginalXTDCTrialsListBox.Enable = "off";
            app.OriginalEMGChannelsLabel.Enable = "off";
            app.OriginalXTDCChannelsListBox.Enable = "off";
            app.OriginalXTDCDataFieldButtonGroup.Enable = "off";
            app.OriginalXTDCRawButton.Enable = "off";
            app.OriginalXTDCFilteredButton.Enable = "off";
            % Original XTDC Plot Button
            app.OriginalXTDCPlotButton.Enable = "off";

            % XTDC
            app.EMGTrialsLabel.Enable = "off";
            app.XTDCTrialsListBox.Enable = "off";
            app.EMGChannelsLabel_2.Enable = "off";
            app.XTDCChannelsListBox.Enable = "off";
            app.EMGChannelsBeforeSMMListBox.Enable = "off";
            app.EMGChannelsLabel.Enable = "off"; % Weird! I cannot change this to 
                                                 % 'EMGChannelsBeforeSMMlistBoxLabel'
            app.XTDCDataFieldButtonGroup.Enable = "off";
            app.XTDCRawButton.Enable = "off";
            app.XTDCFilteredButton.Enable = "off"; 
            % XTDC Plot Button
            app.XTDCPlotHistograms.Enable = "off";
        end

        % Disable the listboxes for PP
        % Disable them after creating PPDC
        function disablePPListBoxes (app)
            app.PPTrialsLabel.Enable = "off";
            app.PPTrialsListBox.Enable = "off";
            app.PPChannelsLabel_2.Enable = "off";
            app.PPChannelsListBox.Enable = "off";
            app.PPChannelsBeforeSMMListBox.Enable = "off";
            app.PPChannelsLabel.Enable = "off"; % Weird! I cannot change this to 
                                                % 'PPChannelsBeforeSMMlistBoxLabel'
            
            % Plot Button
            app.PPButton.Enable = "off";

            % Disable Exporting PPDC to Matlab Workspace
            app.disableExportPPDC();
        end

        function disableXTrialXSegWarning (app)
            app.XTrialXSegWarningLabel.Visible = "off";
            app.XTrialXSegWarningLabel.Enable = "off";
        end

        % Disable XTVariables
        function disableXTVariables (app)
            % Disable the main 'XTDC' label and 'Default' label
            app.XTDCLabel.Enable = "off";
            app.DefaultLabelXTDC.Enable = "off";

            % Disable all variables for XTDC
            app.SensorDropDown.Enable = "off";
            app.SensorDropDownLabel.Enable = "off";
            app.TrialDropDown.Enable = "off";
            app.TrialDropDownLabel.Enable = "off";
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
            % Reset back to default sting for variables above
            app.resetDefaultXTDCVariables;

            % Disable ListBoxes for XTDC
            app.disableXTListBoxes();
            
            % Disable Exporting XTDC to Matlab Workspace
            app.disableExportXTDC();
        end

        % Disable SMMVariables
        function disableSMMVariables (app)
            % Disable Labels
            % Disable the main 'SMM' label and 'Default' label
            app.SMMLabel.Enable = "off";
            app.DefaultLabelSMM.Enable = "off";
            % Disable SMM default SMM variables label
            app.DefaultLabelPX0.Enable = "off";
            app.DefaultLabelPX1.Enable = "off";
            app.DefaultLabelZDelay.Enable = "off";
            app.DefaultLabelNShift.Enable = "off";
            app.DefaultLabelFilterWidth.Enable = "off";
            app.DefaultLabelFilterStd.Enable = "off";

            % Disable all variables for SMM
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
            % Reset back to default sting for variables above
            % app.resetDefaultSMMVariables;

            % Disable PX0PX1 Panel
            app.PX0PX1Panel.Enable = "off";
        end

        % Reset the default labels of XTDC variables to '-'
        function resetDefaultXTDCVariables (app)
            app.DefaultLabelChannelAmpMax.Text = '-';
            app.DefaultLabelChannelAmpMin.Text = '-';
            app.DefaultLabelMapMethod.Text = '-';
            app.DefaultLabelMaxMode.Text = '-';
            app.DefaultLabelNoOfBins.Text = '-';
        end

        % Reset the default labels of SMM variables to '-'
        % This function is not used in the app
        function resetDefaultSMMVariables (app)
            app.DefaultLabelPX0.Text = '-';
            app.DefaultLabelPX1.Text = '-';
            app.DefaultLabelZDelay.Text = '-';
            app.DefaultLabelNShift.Text = '-';
            app.DefaultLabelFilterWidth.Text = '-';
            app.DefaultLabelFilterStd.Text = '-';
        end
        
        % Disable variables concering XTDC and SMM when imported with PK's
        % custom CSVs
        function disable (app)
            % Reset the Yes/No button for time Question in first coloumn
            app.YesCheckBoxFrequencyColumn.Value = 0;
            app.NoCheckBoxFrequencyColumn.Value = 0;

            app.disableYesNoCheckbox();
            app.disableXTNoResultants();

            % Disable the SMM buttons if enabled
            if app.CreateSMMAllButton.Enable == "on"
                app.disableSMM();
            end
            app.disableXTVariables();
            app.disableSMMVariables();
        end

        % Disable Exporting XTDC/PPDC
        function disableExportXTDC (app)
            app.ExportXTDCButton.Enable = "off";
        end
        function disableExportPPDC (app)
            app.ExportPPDCButton.Enable = "off";
        end


    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Initailize smm and original_smm
            app.smm = sdoMultiMat();
            app.original_smm = sdoMultiMat();

            % Default Label Values
            app.DefaultLabelPX0.Text = string(app.original_smm.px0DuraMs);
            app.DefaultLabelPX1.Text = string(app.original_smm.px1DuraMs);
            app.DefaultLabelZDelay.Text = string(app.original_smm.zDelay);
            app.DefaultLabelNShift.Text = string(app.original_smm.nShift);
            app.DefaultLabelFilterWidth.Text = string(app.original_smm.filterWid);
            app.DefaultLabelFilterStd.Text = string(app.original_smm.filterStd);

            % px0DuraMs and px1DuraMs
            app.PX0DuraMsEditField.Value = app.original_smm.px0DuraMs;
            app.PX1DuraMsEditField.Value = app.original_smm.px1DuraMs;

            % zDelay and nShift
            app.ZDelayEditField.Value = app.original_smm.zDelay;
            app.NShiftEditField.Value = app.original_smm.nShift;

            % Filter Width and filterStd
            app.FilterWidthEditField.Value = app.original_smm.filterWid;
            app.FilterStdEditField.Value = app.original_smm.filterStd;

            % % No. of events used depending on sensors
            % app.NoofEventsEditField.Value = app.original_smm.nEventsUsed(1);
            % app.NoofEventsDropDown.Items = app.original_smm.sdoStruct.neuronNames;
            % % Always show the top option (This is useful when the user
            % % decides to create another smm)
            % app.NoofEventsDropDown.Value = app.NoofEventsDropDown.Items{1};


            % PX0PX1 plot
            delete(app.PX0PX1Panel.Children);

            fig = SAT.app_input.plotPx0Px1IntervalGraph('px0DuraMs', app.PX0DuraMsEditField.Value, ...
                'px1DuraMs', app.PX1DuraMsEditField.Value, 'zDelay', ...
                app.ZDelayEditField.Value, 'nShift', app.NShiftEditField.Value);
            axis = fig.Children;
            copyobj(axis, app.PX0PX1Panel);
            delete(fig);

        end

        % Button pushed function: ImportEMGCustButton
        function ImportEMGCustButtonPushed(app, event)
            pk_xt_cell = SAT.app_input.determineXTFileType();

            % Check whether the user inputted something
            if ~isempty(pk_xt_cell)
                app.xt_cell = pk_xt_cell;
                app.disable();
                app.enableYesNoCheckbox();
            end

        end

        % Value changed function: YesCheckBoxFrequencyColumn
        function YesCheckBoxFrequencyColumnValueChanged(app, event)
            value = app.YesCheckBoxFrequencyColumn.Value;
            
            if value
                % GUI
                app.NoCheckBoxFrequencyColumn.Value = 0;
                % Disable the import times/frequency of 'no' button
                app.disableXTNoResultants();

                % Store 'xt_frequency' data
                times = app.xt_cell{1,2}(:,1);
                app.xt_frequency = 1 / (times(2) - times(1));

                % Create temporary xt_cell that don't have time data
                % Remove the first column of data in each trial
                temp_xt_cell = app.xt_cell;
                for i = 1 : height(temp_xt_cell)
                    temp_xt_cell{i,2}(:,1) = [];
                end
                % Remove the time's title
                temp_xt_cell{1,1} = temp_xt_cell{1,1}(2:end);

                % % Store the sensors' name in XT Drop-down menu
                % app.XTChannelsDropDown.Items = temp_xt_cell{1,1};

                % Create the original/copy xtdc datacells
                app.original_xtdc = SAT.app_input.fillXTDC(temp_xt_cell, app.xt_frequency);
                app.xtdc = copy(app.original_xtdc);

                % Check whether pp_cell exists
                % if ~isempty(app.pp_cell)
                if ~isempty(app.ppdc)
                    % Enable Create-SMM button
                    app.enableCreateSMM();
                    % Enable the variable boxes for SMM
                    app.enableSMMVariables();
                end

                % Enable and Fill XT DataCell Variables
                app.enableXTVariables();
                app.fillXTVariable();
                % Fill XTDC ListBoxes for Plotting
                app.fillEMGListBoxes();
            end
        end

        % Value changed function: NoCheckBoxFrequencyColumn
        function NoCheckBoxFrequencyColumnValueChanged(app, event)
            value = app.NoCheckBoxFrequencyColumn.Value;

            if value
                % GUI
                app.YesCheckBoxFrequencyColumn.Value = 0;
                app.enableXTNoResultants();
                % Disable the XT Variables
                app.disableXTVariables();
            end
        end

        % Value changed function: FrequencyEditField
        function FrequencyEditFieldValueChanged(app, event)
            app.xt_frequency = app.FrequencyEditField.Value;

            % % Store the sensors' name in XT Drop-down menu
            % app.XTChannelsDropDown.Items = app.xt_cell{1,1};

            % Create the original/copy xtdc datacells
            app.original_xtdc = SAT.app_input.fillXTDC(app.xt_cell, app.xt_frequency);
            app.xtdc = copy(app.original_xtdc);

            % Check whether pp_cell exists
            % if ~isempty(app.pp_cell)
            if ~isempty(app.ppdc)
                % Enable Create-SMM button
                app.enableCreateSMM();
                % Enable the variable boxes for SMM
                app.enableSMMVariables();
            end

            % Enable and Fill XT DataCell Variables
            app.enableXTVariables();
            app.fillXTVariable();
            % Fill XTDC ListBoxes for Plotting
            app.fillEMGListBoxes();
        end

        % Button pushed function: ImportTimesButton
        function ImportTimesButtonPushed(app, event)
            [file, path] = uigetfile('*.*');
            file_path = fullfile(path, file);

            if file~= 0
                times = readmatrix(file_path);
                % Calculate Frequency
                app.xt_frequency = 1 / (times(2) - times(1));

                % % Store the sensors' name in XT Drop-down menu
                % app.XTChannelsDropDown.Items = app.xt_cell{1,1};

                % Create the original/copy xtdc datacells
                app.original_xtdc = SAT.app_input.fillXTDC(app.xt_cell, app.xt_frequency);
                app.xtdc = copy(app.original_xtdc);

                % Check whether pp_cell exists
                % if ~isempty(app.pp_cell)
                if ~isempty(app.ppdc)
                    % Enable Create-SMM button
                    app.enableCreateSMM();
                    % Enable the variable boxes for SMM
                    app.enableSMMVariables();
                end

                % Enable and Fill XT DataCell Variables
                app.enableXTVariables();
                app.fillXTVariable();
                % Fill XTDC ListBoxes for Plotting
                app.fillEMGListBoxes();

            end
        end

        % Button pushed function: ImportPPCustButton
        function ImportPPCustButtonPushed(app, event)
            % TODO: check whether both values are double and double
            pk_pp_cell = SAT.app_input.determinePPFileType();
            % If the user inputted nothing
            if isempty(pk_pp_cell)
                return;
            end

            app.pp_cell = pk_pp_cell;
            app.original_ppdc = SAT.app_input.fillPPDC(app.pp_cell);
            app.ppdc = copy(app.original_ppdc);

            % Disable the plot button to enforce the user into creating the
            % new SMM
            app.disablePlotSMM();
            app.disableSMMVariables();

            % Fill PPDC ListBoxes for Plotting
            app.fillPPListBoxes();
            % Enable PP ListBoxes for Plotting and creating SMM
            app.enablePPListBoxes();
            
            if ~isempty(app.xtdc)    
                % Enable the createSMM button
                app.enableCreateSMM();
                % Enable the variable boxes for SMM
                app.enableSMMVariables();
            end
            
        end

        % Button pushed function: ImportEMGTrevorButton
        function ImportEMGTrevorButtonPushed(app, event)
            [pk_xt_cell, o_xtdc] = SAT.app_input.getPKEMGCellFromTSEMGCell();
            % If the user inputted nothing
            if isempty(pk_xt_cell) || ~o_xtdc.sampledData
                return;
            end

            app.xt_cell = pk_xt_cell;
            app.original_xtdc = copy(o_xtdc);
            app.xtdc = copy(app.original_xtdc);
            app.xt_frequency = app.xtdc.fs;
            
            app.disable();
            
            % if ~isempty(app.pp_cell)
            if ~isempty(app.ppdc)
                % Enable Create-SMM button
                app.enableCreateSMM();
                % Enable the variable boxes for SMM
                app.enableSMMVariables();
                
            end

            % Enable and Fill XT DataCell Variables
            app.enableXTVariables();
            app.fillXTVariable();
            % Fill XTDC ListBoxes for Plotting
            app.fillEMGListBoxes();
        end

        % Button pushed function: ImportPPTrevorButton
        function ImportPPTrevorButtonPushed(app, event)
            [pk_pp_cell, o_ppdc] = SAT.app_input.getPKPPCellFromTSPPCell();
            % If the user inputted nothing
            if isempty(pk_pp_cell) || ~o_ppdc.sampledData
                return;
            end

            app.pp_cell = pk_pp_cell;
            app.original_ppdc = copy(o_ppdc);
            app.ppdc = copy(app.original_ppdc);

            % Disable the plot button to enforce the user into creating the
            % new SMM
            app.disablePlotSMM();
            app.disableSMMVariables();

            % Fill PPDC ListBoxes for Plotting
            app.fillPPListBoxes();
            % Enable PP ListBoxes for Plotting and creating SMM
            app.enablePPListBoxes();

            if ~isempty(app.xtdc)    
                % Enable the createSMM button
                app.enableCreateSMM();
                % Enable the variable boxes for SMM
                app.enableSMMVariables();
            end


        end

        % Button pushed function: ImportXTDCButton
        function ImportXTDCButtonPushed(app, event)
            % Check whether 'xtdc' variable exists in Matlab workspace
            % If 'xtdc' exists, check whether EMG data is imported
            if evalin('base', "exist('xtdc', 'var')") && evalin('base', "xtdc.sampledData")
                % Get 'xtdc' variable from Matlab workspace
                app.original_xtdc = evalin('base', 'xtdc');
                app.xtdc = copy(app.original_xtdc);
                app.xt_frequency = app.xtdc.fs;

                app.disable();
                
                % Check whether 'ppdc' exists
                if ~isempty(app.ppdc)
                    % Enable Create-SMM button
                    app.enableCreateSMM();
                    % Enable the variable boxes for SMM
                    app.enableSMMVariables();              
                end
    
                % Enable and Fill XT DataCell Variables
                app.enableXTVariables();
                app.fillXTVariable();
                % Fill XTDC ListBoxes for Plotting
                app.fillEMGListBoxes();
            end

        end

        % Button pushed function: ImportPPDCButton
        function ImportPPDCButtonPushed(app, event)
            % Check whether 'ppdc' variable exists in Matlab workspace
            % If 'ppdc' exists, check whether PP data is imported
            if evalin('base', "exist('ppdc', 'var')") && evalin('base', "ppdc.sampledData")
                % Get 'ppdc' variable from Matlab workspace
                app.original_ppdc = evalin('base', 'ppdc');
                app.ppdc = copy(app.original_ppdc);

                % Disable the plot button to enforce the user into creating the
                % new SMM
                app.disablePlotSMM();
                app.disableSMMVariables();
                    
                % Fill PPDC ListBoxes for Plotting
                app.fillPPListBoxes();
                % Enable PP ListBoxes for Plotting and creating SMM
                app.enablePPListBoxes();
    
                if ~isempty(app.xtdc)    
                    % Enable the createSMM button
                    app.enableCreateSMM();
                    % Enable the variable boxes for SMM
                    app.enableSMMVariables();
                end
            end
            
        end

        % Button pushed function: ExportXTDCButton
        function ExportXTDCButtonPushed(app, event)
            % Check if 'app.xtdc' exists
            if ~isempty(app.xtdc)
                org_name = 'app_xtdc'; % Original Name
                base_eval1_str = sprintf("exist('%s', 'var')", org_name); % The code to evaluate in base Matlab workspace
                count = 1; % Used for different variable names
                
                % Get a new variable name if 'org_name' exists in the base
                % Matlab workspace
                while evalin('base', base_eval1_str)
                    new_name = [org_name, num2str(count)];
                    base_eval1_str = sprintf("exist('%s', 'var')", new_name);
                    count = count + 1;  
                end
                
                % Check if we have to create a new variable name 
                if count > 1
                    assignin('base', new_name, app.xtdc);
                    % If you use 'assignin' to a class in matlab, it
                    % assigns by reference, so you need to dereference it
                    base_eval2_str = sprintf('%s = copy(%s)', new_name, new_name);
                else 
                    assignin('base', org_name, app.xtdc);
                    % If you use 'assignin' to a class in matlab, it
                    % assigns by reference, so you need to dereference it
                    base_eval2_str = sprintf('%s = copy(%s)', org_name, org_name);
                end
                evalin('base', base_eval2_str);
            end

        end

        % Button pushed function: ExportPPDCButton
        function ExportPPDCButtonPushed(app, event)
            % Check if 'app.ppdc' exists
            if ~isempty(app.ppdc)
                org_name = 'app_ppdc'; % Original Name
                base_eval1_str = sprintf("exist('%s', 'var')", org_name); % The code to evaluate in base Matlab workspace
                count = 1; % Used for different variable names
                
                % Get a new variable name if 'org_name' exists in the base
                % Matlab workspace
                while evalin('base', base_eval1_str)
                    new_name = [org_name, num2str(count)];
                    base_eval1_str = sprintf("exist('%s', 'var')", new_name);
                    count = count + 1;  
                end
                
                % Check if we have to create a new variable name 
                if count > 1
                    assignin('base', new_name, app.ppdc);
                    % If you use 'assignin' to a class in matlab, it
                    % assigns by reference, so you need to dereference it
                    base_eval2_str = sprintf('%s = copy(%s)', new_name, new_name);
                else 
                    assignin('base', org_name, app.ppdc);
                    % If you use 'assignin' to a class in matlab, it
                    % assigns by reference, so you need to dereference it
                    base_eval2_str = sprintf('%s = copy(%s)', org_name, org_name);
                end
                evalin('base', base_eval2_str);
            end

        end

        % Value changed function: OriginalXTDCTrialsListBox
        function OriginalXTDCTrialsListBoxValueChanged(app, event)
            % Get the index of the selected EMG Trials for plotting
            selected_cell = app.OriginalXTDCTrialsListBox.Value;

            selected_index = cellfun(@(x) find(strcmp(x, app.OriginalXTDCTrialsListBox.Items)), selected_cell);
            app.emg_original_listbox_trial_index = sort(selected_index);
            
        end

        % Value changed function: OriginalXTDCChannelsListBox
        function OriginalXTDCChannelsListBoxValueChanged(app, event)
            % Get the index of the selected EMG Channels for plotting
            selected_cell = app.OriginalXTDCChannelsListBox.Value;

            selected_index = cellfun(@(x) find(strcmp(x, app.OriginalXTDCChannelsListBox.Items)), selected_cell);
            app.emg_original_listbox_channel_index = sort(selected_index);
            
        end

        % Selection changed function: OriginalXTDCDataFieldButtonGroup
        function OriginalXTDCDataFieldButtonGroupSelectionChanged(app, event)
            if ~isempty(app.original_xtdc)
                % Get the text data of the selected button
                selectedButton = app.OriginalXTDCDataFieldButtonGroup.SelectedObject;
                selectedText = strip(selectedButton.Text);
    
                if strcmpi(selectedText, 'raw')
                    app.original_xtdc.dataField = 'raw';
                elseif strcmpi(selectedText, 'filtered')
                    app.original_xtdc.dataField = 'envelope';
                end
            end

        end

        % Button pushed function: OriginalXTDCPlotButton
        function OriginalXTDCPlotButtonPushed(app, event)
            delete(app.EMGPanel.Children);
            
            % Check whether the user selected both the trials and channels
            if ~isempty(app.emg_original_listbox_trial_index) && ~isempty(app.emg_original_listbox_channel_index)               
                app.original_xtdc.plot(app.emg_original_listbox_trial_index, app.emg_original_listbox_channel_index);
                fig = gcf;
                axis = fig.Children;
                axis_copy = copyobj(axis, app.EMGPanel);
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
            end

        end

        % Value changed function: PPTrialsListBox
        function PPTrialsListBoxValueChanged(app, event)
            % Get the index no. from user selected items
            selected_cell = app.PPTrialsListBox.Value;
    
            selected_index = cellfun(@(x) find(strcmp(x, app.PPTrialsListBox.Items)), selected_cell);
            app.pp_listbox_trial_index = sort(selected_index);

        end

        % Value changed function: PPChannelsListBox
        function PPChannelsListBoxValueChanged(app, event)
            % Get the index no. from user selected items
            selected_cell = app.PPChannelsListBox.Value;

            selected_index = cellfun(@(x) find(strcmp(x, app.PPChannelsListBox.Items)), selected_cell);
            app.pp_listbox_channel_index = sort(selected_index);

        end

        % Button pushed function: PPButton
        function PPPlotButtonPushed(app, event)
            delete(app.SpikesRatePanel.Children);
            delete(app.ISIPanel.Children);
            
            % Check whether the user selected both the trials and channels
            if ~isempty(app.pp_listbox_trial_index) && ~isempty(app.pp_listbox_channel_index)
                % Plot Spike Rates
                app.ppdc.plotSpikes(app.pp_listbox_trial_index, app.pp_listbox_channel_index);
                % Put the Spike Rates' plot inside the panel and delete the plot
                fig = gcf;
                axis = fig.Children;
                axis_copy = copyobj(axis, app.SpikesRatePanel);
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
    
                % Plot ISI
                app.ppdc.plotISI(app.pp_listbox_trial_index, app.pp_listbox_channel_index);
                % Put the ISI's plot inside the panel and delete the plot
                fig = gcf;
                axis = fig.Children;
                copyobj(axis, app.ISIPanel);
                % % Copy the Title and Labels
                % axis_copy.Title.String = axis.Title.String;
                % axis_copy.XLabel = axis.XLabel; 
                % axis_copy.YLabel = axis.YLabel;
                % % Copy the X and Y Ticks and Limits
                % axis_copy.XLim = axis.XLim; 
                % axis_copy.YLim = axis.YLim;
                % axis_copy.XTick = axis.XTick;
                % axis_copy.YTick = axis.YTick;
                % % Copy the colormap
                % axis_copy.Colormap = axis.Colormap;
                % Close the figure after copying
                close(fig);
            end

        end

        % Value changed function: SensorDropDown
        function SensorDropDownValueChanged(app, event)
            % Get sensor index
            sensor_value = app.SensorDropDown.Value;
            app.sensor_index = find(strcmp(sensor_value, app.SensorDropDown.Items));
            % Get trial index
            % trial_value = app.TrialDropDown.Value;
            % app.trial_index = find(strcmp(trial_value, app.TrialDropDown.Items));

            % % Set Limits for ChannelAmpMax and ChannelAmpMin
            % app.ChannelAmpMaxEditField.Limits = [app.original_xtdc.channelAmpMin(app.sensor_index, app.trial_index) app.original_xtdc.channelAmpMax(app.sensor_index, app.trial_index)];
            % app.ChannelAmpMinEditField.Limits = [app.original_xtdc.channelAmpMin(app.sensor_index, app.trial_index) app.original_xtdc.channelAmpMax(app.sensor_index, app.trial_index)];

            % Set Limits for ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Limits = [app.xtdc.channelAmpMin(app.sensor_index, app.trial_index), inf];
            app.ChannelAmpMinEditField.Limits = [-inf, app.xtdc.channelAmpMax(app.sensor_index, app.trial_index)];
            % Set the Default Values for ChannelAmpMax and ChannelAmpMin
            app.DefaultLabelChannelAmpMax.Text = string(app.original_xtdc.channelAmpMax(app.sensor_index, app.trial_index));
            app.DefaultLabelChannelAmpMin.Text = string(app.original_xtdc.channelAmpMin(app.sensor_index, app.trial_index));

            % ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Value = app.xtdc.channelAmpMax(app.sensor_index, app.trial_index);
            app.ChannelAmpMinEditField.Value = app.xtdc.channelAmpMin(app.sensor_index, app.trial_index);
            
        end

        % Value changed function: TrialDropDown
        function TrialDropDownValueChanged(app, event)
            % Get trial index
            trial_value = app.TrialDropDown.Value;
            app.trial_index = find(strcmp(trial_value, app.TrialDropDown.Items));

            % Set Limits for ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Limits = [app.xtdc.channelAmpMin(app.sensor_index, app.trial_index), inf];
            app.ChannelAmpMinEditField.Limits = [-inf, app.xtdc.channelAmpMax(app.sensor_index, app.trial_index)];
            % Set the Default Values for ChannelAmpMax and ChannelAmpMin
            app.DefaultLabelChannelAmpMax.Text = string(app.original_xtdc.channelAmpMax(app.sensor_index, app.trial_index));
            app.DefaultLabelChannelAmpMin.Text = string(app.original_xtdc.channelAmpMin(app.sensor_index, app.trial_index));
            
            % ChannelAmpMax and ChannelAmpMin
            app.ChannelAmpMaxEditField.Value = app.xtdc.channelAmpMax(app.sensor_index, app.trial_index);
            app.ChannelAmpMinEditField.Value = app.xtdc.channelAmpMin(app.sensor_index, app.trial_index);

        end

        % Value changed function: ChannelAmpMaxEditField
        function ChannelAmpMaxEditFieldValueChanged(app, event)
            value = app.ChannelAmpMaxEditField.Value;

            % Special Case: When the Max Mode is 'xTrialxSeg'
            if strcmpi(app.MaxModeDropDown.Value, 'xTrialxSeg')
                for i = 1 : app.xtdc.nTrials
                    app.xtdc.channelAmpMax(app.sensor_index, i) = value;

                    % Set Limits for ChannelAmpMax and ChannelAmpMin
                    app.ChannelAmpMaxEditField.Limits = [app.xtdc.channelAmpMin(app.sensor_index, i), inf];
                    app.ChannelAmpMinEditField.Limits = [-inf, app.xtdc.channelAmpMax(app.sensor_index, i)];
                end
            else
                app.xtdc.channelAmpMax(app.sensor_index, app.trial_index) = value;

                % Set Limits for ChannelAmpMax and ChannelAmpMin
                app.ChannelAmpMaxEditField.Limits = [app.xtdc.channelAmpMin(app.sensor_index, app.trial_index), inf];
                app.ChannelAmpMinEditField.Limits = [-inf, app.xtdc.channelAmpMax(app.sensor_index, app.trial_index)];
            end

        end

        % Value changed function: ChannelAmpMinEditField
        function ChannelAmpMinEditFieldValueChanged(app, event)
            value = app.ChannelAmpMinEditField.Value;

            % Special Case: When the Max Mode is 'xTrialxSeg'
            if strcmpi(app.MaxModeDropDown.Value, 'xTrialxSeg')
                for i = 1 : app.xtdc.nTrials
                    app.xtdc.channelAmpMin(app.sensor_index, i) = value;

                    % Set Limits for ChannelAmpMax and ChannelAmpMin
                    app.ChannelAmpMaxEditField.Limits = [app.xtdc.channelAmpMin(app.sensor_index, i), inf];
                    app.ChannelAmpMinEditField.Limits = [-inf, app.xtdc.channelAmpMax(app.sensor_index, i)];
                end
            else
                app.xtdc.channelAmpMin(app.sensor_index, app.trial_index) = value;

                % Set Limits for ChannelAmpMax and ChannelAmpMin
                app.ChannelAmpMaxEditField.Limits = [app.xtdc.channelAmpMin(app.sensor_index, app.trial_index), inf];
                app.ChannelAmpMinEditField.Limits = [-inf, app.xtdc.channelAmpMax(app.sensor_index, app.trial_index)];
            end

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

            if strcmpi(app.xtdc.maxMode, 'xTrialxSeg')
                app.enableXTrialXSegWarning();
            else
                app.disableXTrialXSegWarning();
            end

        end

        % Value changed function: NoofBinsSpinner
        function NoofBinsSpinnerValueChanged(app, event)
            value = app.NoofBinsSpinner.Value;
            app.xtdc.nBins = value;
            app.xtdc.discretize();

        end

        % Value changed function: XTDCTrialsListBox
        function XTDCTrialsListBoxValueChanged(app, event)
            % Get the index no. from user selected items
            selected_cell = app.XTDCTrialsListBox.Value;

            selected_index = cellfun(@(x) find(strcmp(x, app.XTDCTrialsListBox.Items)), selected_cell);
            app.emg_listbox_trial_index = sort(selected_index);

        end

        % Value changed function: XTDCChannelsListBox
        function XTDCChannelsListBoxValueChanged(app, event)
            % Get the index no. from user selected items
            selected_cell = app.XTDCChannelsListBox.Value;

            selected_index = cellfun(@(x) find(strcmp(x, app.XTDCChannelsListBox.Items)), selected_cell);
            app.emg_listbox_channel_index = sort(selected_index);

        end

        % Selection changed function: XTDCDataFieldButtonGroup
        function XTDCDataFieldButtonGroupSelectionChanged(app, event)
            if ~isempty(app.xtdc)
                % Get the text data of the selected button
                selectedButton = app.XTDCDataFieldButtonGroup.SelectedObject;
                selectedText = strip(selectedButton.Text);

                if strcmpi(selectedText, 'raw')
                    app.xtdc.dataField = 'raw';
                elseif strcmpi(selectedText, 'filtered')
                    app.xtdc.dataField = 'envelope';
                end
            end
        end

        % Button pushed function: XTDCPlotHistograms
        function EMGPlotButtonPushed(app, event)
            % delete(app.EMGPanel.Children);
            delete(app.StateEMGHistogram.Children);
            delete(app.RawEMGHistogram.Children);
            
            % Check whether the user selected both the trials and channels
            if ~isempty(app.emg_listbox_trial_index) && ~isempty(app.emg_listbox_channel_index)
                
                % Get the legend names and colors for the histograms
                legend_names = app.xtdc.sensor(app.emg_listbox_channel_index);
                color_map = lines(length(legend_names));
    
                % STATE HISTOGRAM
                % Discretize to the user inputted bins
                app.xtdc.discretize();
                % Get the user selected discretized bin tensor
                state_tensor = app.xtdc.getTensor(app.emg_listbox_channel_index, ...
                    app.emg_listbox_trial_index,'DATAFIELD','stateSignal');             
    
                % Loop through the channels and plot histograms
                for ch_no = 1 : size(state_tensor,1)
                    histogram(app.StateEMGHistogram, state_tensor(ch_no,:,:), 'FaceAlpha', 0.5, ...
                        'EdgeColor', 'None');
                    hold (app.StateEMGHistogram, "on");
                end
                % Initialize graphic objects for lines' object
                graphic_objects = gobjects(size(state_tensor,1));
                % Loop through each channel to plot nothing for new legends since
                % Matlab results a weird error of legends not having colors
                for ch_no = 1 : size(state_tensor,1)
                    graphic_objects(ch_no)= plot(app.StateEMGHistogram, 0, 0, 'Color', color_map(ch_no,:), ...
                        'DisplayName', legend_names{ch_no});
                    if ch_no ~= size(state_tensor,1)
                        hold (app.StateEMGHistogram, "on");
                    else
                        hold (app.StateEMGHistogram, "off");
                    end
                end
                legend(app.StateEMGHistogram, graphic_objects(:,1));
    
                % RAW OR FILTERED HISTOGRAM
                xtdc_datafield = strip(app.xtdc.dataField);
                if strcmpi(xtdc_datafield, 'raw') % raw
                    tensor = app.xtdc.getTensor(app.emg_listbox_channel_index, ...
                        app.emg_listbox_trial_index,'DATAFIELD','raw');
                elseif strcmpi(xtdc_datafield,'envelope') % filtered
                    tensor = app.xtdc.getTensor(app.emg_listbox_channel_index, ...
                        app.emg_listbox_trial_index,'DATAFIELD','envelope');
                end

                for ch_no = 1 : size(tensor,1)
                    histogram(app.RawEMGHistogram, tensor(ch_no,:,:), 'FaceAlpha', 0.5, ...
                        'EdgeColor', 'None');
                    hold (app.RawEMGHistogram, "on");
                end
                % Initialize graphic objects for lines' object
                graphic_objects = gobjects(size(tensor,1));
                % Loop through each channel to plot nothing for new legends since
                % Matlab results a weird error of legends not having colors
                for ch_no = 1 : size(tensor,1)
                    graphic_objects(ch_no)= plot(app.RawEMGHistogram, 0, 0, 'Color', color_map(ch_no,:), ...
                        'DisplayName', legend_names{ch_no});
                    if ch_no ~= size(tensor,1)
                        hold (app.RawEMGHistogram, "on");
                    else
                        hold (app.RawEMGHistogram, "off");
                    end
                end
                legend(app.RawEMGHistogram, graphic_objects(:,1));
            end

        end

        % Value changed function: PX0DuraMsEditField
        function PX0DuraMsEditFieldValueChanged(app, event)
            value = app.PX0DuraMsEditField.Value;
            app.smm.px0DuraMs = value;

            delete(app.PX0PX1Panel.Children);

            fig = SAT.app_input.plotPx0Px1IntervalGraph('px0DuraMs', value, ...
                'px1DuraMs', app.PX1DuraMsEditField.Value, 'zDelay', ...
                app.ZDelayEditField.Value, 'nShift', app.NShiftEditField.Value);
            axis = fig.Children;
            copyobj(axis, app.PX0PX1Panel);
            delete(fig);

        end

        % Value changed function: PX1DuraMsEditField
        function PX1DuraMsEditFieldValueChanged(app, event)
            value = app.PX1DuraMsEditField.Value;
            app.smm.px1DuraMs = value;

            delete(app.PX0PX1Panel.Children);

            fig = SAT.app_input.plotPx0Px1IntervalGraph('px0DuraMs', app.PX0DuraMsEditField.Value, ...
                'px1DuraMs', value, 'zDelay', ...
                app.ZDelayEditField.Value, 'nShift', app.NShiftEditField.Value);
            axis = fig.Children;
            copyobj(axis, app.PX0PX1Panel);
            delete(fig);

        end

        % Value changed function: ZDelayEditField
        function ZDelayEditFieldValueChanged(app, event)
            value = app.ZDelayEditField.Value;
            app.smm.zDelay = value;

            delete(app.PX0PX1Panel.Children);

            fig = SAT.app_input.plotPx0Px1IntervalGraph('px0DuraMs', app.PX0DuraMsEditField.Value, ...
                'px1DuraMs', app.PX1DuraMsEditField.Value, 'zDelay', ...
                value, 'nShift', app.NShiftEditField.Value);
            axis = fig.Children;
            copyobj(axis, app.PX0PX1Panel);
            delete(fig);

        end

        % Value changed function: NShiftEditField
        function NShiftEditFieldValueChanged(app, event)
            value = app.NShiftEditField.Value;
            app.smm.nShift = value;

            delete(app.PX0PX1Panel.Children);

            fig = SAT.app_input.plotPx0Px1IntervalGraph('px0DuraMs', app.PX0DuraMsEditField.Value, ...
                'px1DuraMs', app.PX1DuraMsEditField.Value, 'zDelay', ...
                app.ZDelayEditField.Value, 'nShift', value);
            axis = fig.Children;
            copyobj(axis, app.PX0PX1Panel);
            delete(fig);

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
            emg_selected_cell = app.EMGChannelsBeforeSMMListBox.Value;
            pp_selected_cell = app.PPChannelsBeforeSMMListBox.Value;
            emg_selected_index = cellfun(@(x) find(strcmp(x, app.EMGChannelsBeforeSMMListBox.Items)), emg_selected_cell);
            pp_selected_index = cellfun(@(x) find(strcmp(x, app.PPChannelsBeforeSMMListBox.Items)), pp_selected_cell);

            if ~isempty(emg_selected_index) && ~isempty(pp_selected_index)
                app.createSMM(emg_selected_index, pp_selected_index);
            end

        end

        % Button pushed function: CreateSMMAllButton
        function CreateSMMAllButtonPushed(app, event)
            app.createSMM();

        end

        % Button pushed function: SMMPlotButton
        function SMMPlotButtonPushed(app, event)
            app.plotSMM();

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [93 93 1094 2405];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Scrollable = 'on';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {50, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 50};
            app.GridLayout.RowHeight = {40, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 40, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 40, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 300, 400, 40};
            app.GridLayout.ColumnSpacing = 1.66666666666667;
            app.GridLayout.RowSpacing = 7.36956455396569;
            app.GridLayout.Padding = [1.66666666666667 7.36956455396569 1.66666666666667 7.36956455396569];
            app.GridLayout.Scrollable = 'on';

            % Create StateEMGHistogram
            app.StateEMGHistogram = uiaxes(app.GridLayout);
            title(app.StateEMGHistogram, 'State Histogram')
            xlabel(app.StateEMGHistogram, 'No. of Bins')
            ylabel(app.StateEMGHistogram, 'Frequency')
            zlabel(app.StateEMGHistogram, 'Z')
            app.StateEMGHistogram.Layout.Row = [32 38];
            app.StateEMGHistogram.Layout.Column = [27 38];

            % Create RawEMGHistogram
            app.RawEMGHistogram = uiaxes(app.GridLayout);
            title(app.RawEMGHistogram, 'EMG Histogram')
            xlabel(app.RawEMGHistogram, 'Amplitude')
            ylabel(app.RawEMGHistogram, 'Frequency')
            zlabel(app.RawEMGHistogram, 'Z')
            app.RawEMGHistogram.Layout.Row = [25 31];
            app.RawEMGHistogram.Layout.Column = [27 38];

            % Create VariableViewingLabel
            app.VariableViewingLabel = uilabel(app.GridLayout);
            app.VariableViewingLabel.HorizontalAlignment = 'center';
            app.VariableViewingLabel.FontSize = 18;
            app.VariableViewingLabel.FontWeight = 'bold';
            app.VariableViewingLabel.Layout.Row = 1;
            app.VariableViewingLabel.Layout.Column = [2 38];
            app.VariableViewingLabel.Text = 'Variable Viewing';

            % Create EMGDataLabel
            app.EMGDataLabel = uilabel(app.GridLayout);
            app.EMGDataLabel.HorizontalAlignment = 'center';
            app.EMGDataLabel.FontSize = 18;
            app.EMGDataLabel.Layout.Row = 2;
            app.EMGDataLabel.Layout.Column = [3 25];
            app.EMGDataLabel.Text = 'EMG Data';

            % Create ImportEMGTrevorButton
            app.ImportEMGTrevorButton = uibutton(app.GridLayout, 'push');
            app.ImportEMGTrevorButton.ButtonPushedFcn = createCallbackFcn(app, @ImportEMGTrevorButtonPushed, true);
            app.ImportEMGTrevorButton.Layout.Row = 3;
            app.ImportEMGTrevorButton.Layout.Column = [2 6];
            app.ImportEMGTrevorButton.Text = 'Import EMG Trevor';

            % Create CustomImportQuestion
            app.CustomImportQuestion = uilabel(app.GridLayout);
            app.CustomImportQuestion.HorizontalAlignment = 'center';
            app.CustomImportQuestion.Enable = 'off';
            app.CustomImportQuestion.Visible = 'off';
            app.CustomImportQuestion.Layout.Row = 3;
            app.CustomImportQuestion.Layout.Column = [14 24];
            app.CustomImportQuestion.Text = 'Is Times data on the first column of the CSV file?';

            % Create EMGPanel
            app.EMGPanel = uipanel(app.GridLayout);
            app.EMGPanel.Title = 'EMG';
            app.EMGPanel.Layout.Row = [3 10];
            app.EMGPanel.Layout.Column = [27 38];

            % Create ImportEMGCustButton
            app.ImportEMGCustButton = uibutton(app.GridLayout, 'push');
            app.ImportEMGCustButton.ButtonPushedFcn = createCallbackFcn(app, @ImportEMGCustButtonPushed, true);
            app.ImportEMGCustButton.WordWrap = 'on';
            app.ImportEMGCustButton.Layout.Row = 4;
            app.ImportEMGCustButton.Layout.Column = [2 6];
            app.ImportEMGCustButton.Text = 'Import EMG Cust.';

            % Create ExportXTDCButton
            app.ExportXTDCButton = uibutton(app.GridLayout, 'push');
            app.ExportXTDCButton.ButtonPushedFcn = createCallbackFcn(app, @ExportXTDCButtonPushed, true);
            app.ExportXTDCButton.Enable = 'off';
            app.ExportXTDCButton.Layout.Row = 4;
            app.ExportXTDCButton.Layout.Column = [8 12];
            app.ExportXTDCButton.Text = 'Export XTDC';

            % Create YesCheckBoxFrequencyColumn
            app.YesCheckBoxFrequencyColumn = uicheckbox(app.GridLayout);
            app.YesCheckBoxFrequencyColumn.ValueChangedFcn = createCallbackFcn(app, @YesCheckBoxFrequencyColumnValueChanged, true);
            app.YesCheckBoxFrequencyColumn.Enable = 'off';
            app.YesCheckBoxFrequencyColumn.Visible = 'off';
            app.YesCheckBoxFrequencyColumn.Text = 'Yes';
            app.YesCheckBoxFrequencyColumn.Layout.Row = 4;
            app.YesCheckBoxFrequencyColumn.Layout.Column = [16 17];

            % Create NoCheckBoxFrequencyColumn
            app.NoCheckBoxFrequencyColumn = uicheckbox(app.GridLayout);
            app.NoCheckBoxFrequencyColumn.ValueChangedFcn = createCallbackFcn(app, @NoCheckBoxFrequencyColumnValueChanged, true);
            app.NoCheckBoxFrequencyColumn.Enable = 'off';
            app.NoCheckBoxFrequencyColumn.Visible = 'off';
            app.NoCheckBoxFrequencyColumn.Text = 'No';
            app.NoCheckBoxFrequencyColumn.Layout.Row = 4;
            app.NoCheckBoxFrequencyColumn.Layout.Column = [22 23];

            % Create ImportXTDCButton
            app.ImportXTDCButton = uibutton(app.GridLayout, 'push');
            app.ImportXTDCButton.ButtonPushedFcn = createCallbackFcn(app, @ImportXTDCButtonPushed, true);
            app.ImportXTDCButton.Layout.Row = 5;
            app.ImportXTDCButton.Layout.Column = [2 6];
            app.ImportXTDCButton.Text = 'Import XTDC';

            % Create FrequencyEditFieldLabel
            app.FrequencyEditFieldLabel = uilabel(app.GridLayout);
            app.FrequencyEditFieldLabel.HorizontalAlignment = 'center';
            app.FrequencyEditFieldLabel.Visible = 'off';
            app.FrequencyEditFieldLabel.Layout.Row = 5;
            app.FrequencyEditFieldLabel.Layout.Column = [14 15];
            app.FrequencyEditFieldLabel.Text = 'Frequency';

            % Create FrequencyEditField
            app.FrequencyEditField = uieditfield(app.GridLayout, 'numeric');
            app.FrequencyEditField.ValueChangedFcn = createCallbackFcn(app, @FrequencyEditFieldValueChanged, true);
            app.FrequencyEditField.Visible = 'off';
            app.FrequencyEditField.Layout.Row = 5;
            app.FrequencyEditField.Layout.Column = [16 18];

            % Create ORLabel
            app.ORLabel = uilabel(app.GridLayout);
            app.ORLabel.HorizontalAlignment = 'center';
            app.ORLabel.FontColor = [1 0 0];
            app.ORLabel.Visible = 'off';
            app.ORLabel.Layout.Row = 5;
            app.ORLabel.Layout.Column = 20;
            app.ORLabel.Text = 'OR';

            % Create ImportTimesButton
            app.ImportTimesButton = uibutton(app.GridLayout, 'push');
            app.ImportTimesButton.ButtonPushedFcn = createCallbackFcn(app, @ImportTimesButtonPushed, true);
            app.ImportTimesButton.Visible = 'off';
            app.ImportTimesButton.Layout.Row = 5;
            app.ImportTimesButton.Layout.Column = [22 24];
            app.ImportTimesButton.Text = 'Import Times';

            % Create OriginalEMGTrialsLabel
            app.OriginalEMGTrialsLabel = uilabel(app.GridLayout);
            app.OriginalEMGTrialsLabel.HorizontalAlignment = 'center';
            app.OriginalEMGTrialsLabel.Enable = 'off';
            app.OriginalEMGTrialsLabel.Layout.Row = [8 11];
            app.OriginalEMGTrialsLabel.Layout.Column = [2 4];
            app.OriginalEMGTrialsLabel.Text = {'Original EMG '; 'Trials'};

            % Create OriginalXTDCTrialsListBox
            app.OriginalXTDCTrialsListBox = uilistbox(app.GridLayout);
            app.OriginalXTDCTrialsListBox.Items = {};
            app.OriginalXTDCTrialsListBox.Multiselect = 'on';
            app.OriginalXTDCTrialsListBox.ValueChangedFcn = createCallbackFcn(app, @OriginalXTDCTrialsListBoxValueChanged, true);
            app.OriginalXTDCTrialsListBox.Enable = 'off';
            app.OriginalXTDCTrialsListBox.Layout.Row = [8 11];
            app.OriginalXTDCTrialsListBox.Layout.Column = [5 9];
            app.OriginalXTDCTrialsListBox.Value = {};

            % Create OriginalEMGChannelsLabel
            app.OriginalEMGChannelsLabel = uilabel(app.GridLayout);
            app.OriginalEMGChannelsLabel.HorizontalAlignment = 'center';
            app.OriginalEMGChannelsLabel.Enable = 'off';
            app.OriginalEMGChannelsLabel.Layout.Row = [8 11];
            app.OriginalEMGChannelsLabel.Layout.Column = [11 13];
            app.OriginalEMGChannelsLabel.Text = {'Original EMG '; 'Channels'};

            % Create OriginalXTDCChannelsListBox
            app.OriginalXTDCChannelsListBox = uilistbox(app.GridLayout);
            app.OriginalXTDCChannelsListBox.Items = {};
            app.OriginalXTDCChannelsListBox.Multiselect = 'on';
            app.OriginalXTDCChannelsListBox.ValueChangedFcn = createCallbackFcn(app, @OriginalXTDCChannelsListBoxValueChanged, true);
            app.OriginalXTDCChannelsListBox.Enable = 'off';
            app.OriginalXTDCChannelsListBox.Layout.Row = [8 11];
            app.OriginalXTDCChannelsListBox.Layout.Column = [14 18];
            app.OriginalXTDCChannelsListBox.Value = {};

            % Create OriginalXTDCDataFieldButtonGroup
            app.OriginalXTDCDataFieldButtonGroup = uibuttongroup(app.GridLayout);
            app.OriginalXTDCDataFieldButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @OriginalXTDCDataFieldButtonGroupSelectionChanged, true);
            app.OriginalXTDCDataFieldButtonGroup.Enable = 'off';
            app.OriginalXTDCDataFieldButtonGroup.TitlePosition = 'centertop';
            app.OriginalXTDCDataFieldButtonGroup.Title = 'Original XTDC Data Field';
            app.OriginalXTDCDataFieldButtonGroup.Layout.Row = [8 11];
            app.OriginalXTDCDataFieldButtonGroup.Layout.Column = [20 23];

            % Create OriginalXTDCRawButton
            app.OriginalXTDCRawButton = uitogglebutton(app.OriginalXTDCDataFieldButtonGroup);
            app.OriginalXTDCRawButton.Enable = 'off';
            app.OriginalXTDCRawButton.Text = 'Raw';
            app.OriginalXTDCRawButton.Position = [15 56 75 22];

            % Create OriginalXTDCFilteredButton
            app.OriginalXTDCFilteredButton = uitogglebutton(app.OriginalXTDCDataFieldButtonGroup);
            app.OriginalXTDCFilteredButton.Enable = 'off';
            app.OriginalXTDCFilteredButton.Text = 'Filtered';
            app.OriginalXTDCFilteredButton.Position = [15 21 75 22];
            app.OriginalXTDCFilteredButton.Value = true;

            % Create SpikesRatePanel
            app.SpikesRatePanel = uipanel(app.GridLayout);
            app.SpikesRatePanel.Title = 'Spikes Rate';
            app.SpikesRatePanel.Layout.Row = [11 16];
            app.SpikesRatePanel.Layout.Column = [27 38];

            % Create OriginalXTDCPlotButton
            app.OriginalXTDCPlotButton = uibutton(app.GridLayout, 'push');
            app.OriginalXTDCPlotButton.ButtonPushedFcn = createCallbackFcn(app, @OriginalXTDCPlotButtonPushed, true);
            app.OriginalXTDCPlotButton.Enable = 'off';
            app.OriginalXTDCPlotButton.Layout.Row = 12;
            app.OriginalXTDCPlotButton.Layout.Column = [12 16];
            app.OriginalXTDCPlotButton.Text = 'Original EMG Plot';

            % Create PPDataLabel
            app.PPDataLabel = uilabel(app.GridLayout);
            app.PPDataLabel.HorizontalAlignment = 'center';
            app.PPDataLabel.FontSize = 18;
            app.PPDataLabel.Layout.Row = 13;
            app.PPDataLabel.Layout.Column = [3 25];
            app.PPDataLabel.Text = 'PP Data';

            % Create ImportPPTrevorButton
            app.ImportPPTrevorButton = uibutton(app.GridLayout, 'push');
            app.ImportPPTrevorButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPPTrevorButtonPushed, true);
            app.ImportPPTrevorButton.Layout.Row = 14;
            app.ImportPPTrevorButton.Layout.Column = [2 6];
            app.ImportPPTrevorButton.Text = 'Import PP Trevor';

            % Create ImportPPCustButton
            app.ImportPPCustButton = uibutton(app.GridLayout, 'push');
            app.ImportPPCustButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPPCustButtonPushed, true);
            app.ImportPPCustButton.WordWrap = 'on';
            app.ImportPPCustButton.Layout.Row = 15;
            app.ImportPPCustButton.Layout.Column = [2 6];
            app.ImportPPCustButton.Text = 'Import PP Cust.';

            % Create ExportPPDCButton
            app.ExportPPDCButton = uibutton(app.GridLayout, 'push');
            app.ExportPPDCButton.ButtonPushedFcn = createCallbackFcn(app, @ExportPPDCButtonPushed, true);
            app.ExportPPDCButton.Enable = 'off';
            app.ExportPPDCButton.Layout.Row = 15;
            app.ExportPPDCButton.Layout.Column = [8 12];
            app.ExportPPDCButton.Text = 'Export PPDC';

            % Create ImportPPDCButton
            app.ImportPPDCButton = uibutton(app.GridLayout, 'push');
            app.ImportPPDCButton.ButtonPushedFcn = createCallbackFcn(app, @ImportPPDCButtonPushed, true);
            app.ImportPPDCButton.Layout.Row = 16;
            app.ImportPPDCButton.Layout.Column = [2 6];
            app.ImportPPDCButton.Text = 'Import PPDC';

            % Create ISIPanel
            app.ISIPanel = uipanel(app.GridLayout);
            app.ISIPanel.Title = 'ISI';
            app.ISIPanel.Layout.Row = [17 22];
            app.ISIPanel.Layout.Column = [27 38];

            % Create PPTrialsLabel
            app.PPTrialsLabel = uilabel(app.GridLayout);
            app.PPTrialsLabel.HorizontalAlignment = 'center';
            app.PPTrialsLabel.Enable = 'off';
            app.PPTrialsLabel.Layout.Row = [18 21];
            app.PPTrialsLabel.Layout.Column = [2 4];
            app.PPTrialsLabel.Text = {'PP '; 'Trials'};

            % Create PPTrialsListBox
            app.PPTrialsListBox = uilistbox(app.GridLayout);
            app.PPTrialsListBox.Items = {};
            app.PPTrialsListBox.Multiselect = 'on';
            app.PPTrialsListBox.ValueChangedFcn = createCallbackFcn(app, @PPTrialsListBoxValueChanged, true);
            app.PPTrialsListBox.Enable = 'off';
            app.PPTrialsListBox.Layout.Row = [18 21];
            app.PPTrialsListBox.Layout.Column = [5 9];
            app.PPTrialsListBox.Value = {};

            % Create PPChannelsLabel_2
            app.PPChannelsLabel_2 = uilabel(app.GridLayout);
            app.PPChannelsLabel_2.HorizontalAlignment = 'center';
            app.PPChannelsLabel_2.Enable = 'off';
            app.PPChannelsLabel_2.Layout.Row = [18 21];
            app.PPChannelsLabel_2.Layout.Column = [11 13];
            app.PPChannelsLabel_2.Text = {'PP '; 'Channels'};

            % Create PPChannelsListBox
            app.PPChannelsListBox = uilistbox(app.GridLayout);
            app.PPChannelsListBox.Items = {};
            app.PPChannelsListBox.Multiselect = 'on';
            app.PPChannelsListBox.ValueChangedFcn = createCallbackFcn(app, @PPChannelsListBoxValueChanged, true);
            app.PPChannelsListBox.Enable = 'off';
            app.PPChannelsListBox.Layout.Row = [18 21];
            app.PPChannelsListBox.Layout.Column = [14 18];
            app.PPChannelsListBox.Value = {};

            % Create PPButton
            app.PPButton = uibutton(app.GridLayout, 'push');
            app.PPButton.ButtonPushedFcn = createCallbackFcn(app, @PPPlotButtonPushed, true);
            app.PPButton.Enable = 'off';
            app.PPButton.Layout.Row = 19;
            app.PPButton.Layout.Column = [21 25];
            app.PPButton.Text = 'PP Button';

            % Create HTMLLineBreak
            app.HTMLLineBreak = uihtml(app.GridLayout);
            app.HTMLLineBreak.HTMLSource = '<hr>';
            app.HTMLLineBreak.Layout.Row = 23;
            app.HTMLLineBreak.Layout.Column = [1 39];

            % Create XTDCHistogramsLabel
            app.XTDCHistogramsLabel = uilabel(app.GridLayout);
            app.XTDCHistogramsLabel.HorizontalAlignment = 'center';
            app.XTDCHistogramsLabel.FontSize = 18;
            app.XTDCHistogramsLabel.FontWeight = 'bold';
            app.XTDCHistogramsLabel.Layout.Row = 24;
            app.XTDCHistogramsLabel.Layout.Column = [2 38];
            app.XTDCHistogramsLabel.Text = 'XTDC Histograms';

            % Create XTDCLabel
            app.XTDCLabel = uilabel(app.GridLayout);
            app.XTDCLabel.HorizontalAlignment = 'center';
            app.XTDCLabel.Enable = 'off';
            app.XTDCLabel.Layout.Row = 26;
            app.XTDCLabel.Layout.Column = [5 7];
            app.XTDCLabel.Text = 'XTDC';

            % Create DefaultLabelXTDC
            app.DefaultLabelXTDC = uilabel(app.GridLayout);
            app.DefaultLabelXTDC.HorizontalAlignment = 'center';
            app.DefaultLabelXTDC.Enable = 'off';
            app.DefaultLabelXTDC.Layout.Row = 26;
            app.DefaultLabelXTDC.Layout.Column = [11 13];
            app.DefaultLabelXTDC.Text = 'Default';

            % Create EMGTrialsLabel
            app.EMGTrialsLabel = uilabel(app.GridLayout);
            app.EMGTrialsLabel.HorizontalAlignment = 'center';
            app.EMGTrialsLabel.Enable = 'off';
            app.EMGTrialsLabel.Layout.Row = [26 29];
            app.EMGTrialsLabel.Layout.Column = [15 17];
            app.EMGTrialsLabel.Text = {'EMG '; 'Trials'};

            % Create XTDCTrialsListBox
            app.XTDCTrialsListBox = uilistbox(app.GridLayout);
            app.XTDCTrialsListBox.Items = {};
            app.XTDCTrialsListBox.Multiselect = 'on';
            app.XTDCTrialsListBox.ValueChangedFcn = createCallbackFcn(app, @XTDCTrialsListBoxValueChanged, true);
            app.XTDCTrialsListBox.Enable = 'off';
            app.XTDCTrialsListBox.Layout.Row = [26 29];
            app.XTDCTrialsListBox.Layout.Column = [18 22];
            app.XTDCTrialsListBox.Value = {};

            % Create SensorDropDownLabel
            app.SensorDropDownLabel = uilabel(app.GridLayout);
            app.SensorDropDownLabel.HorizontalAlignment = 'center';
            app.SensorDropDownLabel.Enable = 'off';
            app.SensorDropDownLabel.Layout.Row = 27;
            app.SensorDropDownLabel.Layout.Column = [2 5];
            app.SensorDropDownLabel.Text = 'Sensor';

            % Create SensorDropDown
            app.SensorDropDown = uidropdown(app.GridLayout);
            app.SensorDropDown.Items = {};
            app.SensorDropDown.ValueChangedFcn = createCallbackFcn(app, @SensorDropDownValueChanged, true);
            app.SensorDropDown.Enable = 'off';
            app.SensorDropDown.Layout.Row = 27;
            app.SensorDropDown.Layout.Column = [6 9];
            app.SensorDropDown.Value = {};

            % Create TrialDropDownLabel
            app.TrialDropDownLabel = uilabel(app.GridLayout);
            app.TrialDropDownLabel.HorizontalAlignment = 'center';
            app.TrialDropDownLabel.Enable = 'off';
            app.TrialDropDownLabel.Layout.Row = 28;
            app.TrialDropDownLabel.Layout.Column = [2 5];
            app.TrialDropDownLabel.Text = 'Trial';

            % Create TrialDropDown
            app.TrialDropDown = uidropdown(app.GridLayout);
            app.TrialDropDown.Items = {};
            app.TrialDropDown.ValueChangedFcn = createCallbackFcn(app, @TrialDropDownValueChanged, true);
            app.TrialDropDown.Enable = 'off';
            app.TrialDropDown.Layout.Row = 28;
            app.TrialDropDown.Layout.Column = [6 9];
            app.TrialDropDown.Value = {};

            % Create ChannelAmpMaxEditFieldLabel
            app.ChannelAmpMaxEditFieldLabel = uilabel(app.GridLayout);
            app.ChannelAmpMaxEditFieldLabel.HorizontalAlignment = 'center';
            app.ChannelAmpMaxEditFieldLabel.Enable = 'off';
            app.ChannelAmpMaxEditFieldLabel.Layout.Row = 29;
            app.ChannelAmpMaxEditFieldLabel.Layout.Column = [2 5];
            app.ChannelAmpMaxEditFieldLabel.Text = 'ChannelAmpMax';

            % Create ChannelAmpMaxEditField
            app.ChannelAmpMaxEditField = uieditfield(app.GridLayout, 'numeric');
            app.ChannelAmpMaxEditField.ValueChangedFcn = createCallbackFcn(app, @ChannelAmpMaxEditFieldValueChanged, true);
            app.ChannelAmpMaxEditField.Enable = 'off';
            app.ChannelAmpMaxEditField.Layout.Row = 29;
            app.ChannelAmpMaxEditField.Layout.Column = [6 9];

            % Create DefaultLabelChannelAmpMax
            app.DefaultLabelChannelAmpMax = uilabel(app.GridLayout);
            app.DefaultLabelChannelAmpMax.HorizontalAlignment = 'center';
            app.DefaultLabelChannelAmpMax.Layout.Row = 29;
            app.DefaultLabelChannelAmpMax.Layout.Column = [11 13];
            app.DefaultLabelChannelAmpMax.Text = '-';

            % Create ChannelAmpMinEditFieldLabel
            app.ChannelAmpMinEditFieldLabel = uilabel(app.GridLayout);
            app.ChannelAmpMinEditFieldLabel.HorizontalAlignment = 'center';
            app.ChannelAmpMinEditFieldLabel.Enable = 'off';
            app.ChannelAmpMinEditFieldLabel.Layout.Row = 30;
            app.ChannelAmpMinEditFieldLabel.Layout.Column = [2 5];
            app.ChannelAmpMinEditFieldLabel.Text = 'ChannelAmpMin';

            % Create ChannelAmpMinEditField
            app.ChannelAmpMinEditField = uieditfield(app.GridLayout, 'numeric');
            app.ChannelAmpMinEditField.ValueChangedFcn = createCallbackFcn(app, @ChannelAmpMinEditFieldValueChanged, true);
            app.ChannelAmpMinEditField.Enable = 'off';
            app.ChannelAmpMinEditField.Layout.Row = 30;
            app.ChannelAmpMinEditField.Layout.Column = [6 9];

            % Create DefaultLabelChannelAmpMin
            app.DefaultLabelChannelAmpMin = uilabel(app.GridLayout);
            app.DefaultLabelChannelAmpMin.HorizontalAlignment = 'center';
            app.DefaultLabelChannelAmpMin.Layout.Row = 30;
            app.DefaultLabelChannelAmpMin.Layout.Column = [11 13];
            app.DefaultLabelChannelAmpMin.Text = '-';

            % Create EMGChannelsLabel_2
            app.EMGChannelsLabel_2 = uilabel(app.GridLayout);
            app.EMGChannelsLabel_2.HorizontalAlignment = 'center';
            app.EMGChannelsLabel_2.Enable = 'off';
            app.EMGChannelsLabel_2.Layout.Row = [30 33];
            app.EMGChannelsLabel_2.Layout.Column = [15 17];
            app.EMGChannelsLabel_2.Text = {'EMG '; 'Channels'};

            % Create XTDCChannelsListBox
            app.XTDCChannelsListBox = uilistbox(app.GridLayout);
            app.XTDCChannelsListBox.Items = {};
            app.XTDCChannelsListBox.Multiselect = 'on';
            app.XTDCChannelsListBox.ValueChangedFcn = createCallbackFcn(app, @XTDCChannelsListBoxValueChanged, true);
            app.XTDCChannelsListBox.Enable = 'off';
            app.XTDCChannelsListBox.Layout.Row = [30 33];
            app.XTDCChannelsListBox.Layout.Column = [18 22];
            app.XTDCChannelsListBox.Value = {};

            % Create MapMethodDropDownLabel
            app.MapMethodDropDownLabel = uilabel(app.GridLayout);
            app.MapMethodDropDownLabel.HorizontalAlignment = 'center';
            app.MapMethodDropDownLabel.Enable = 'off';
            app.MapMethodDropDownLabel.Layout.Row = 31;
            app.MapMethodDropDownLabel.Layout.Column = [2 5];
            app.MapMethodDropDownLabel.Text = 'Map Method';

            % Create MapMethodDropDown
            app.MapMethodDropDown = uidropdown(app.GridLayout);
            app.MapMethodDropDown.Items = {'linear', 'log', 'linearsigned', 'logsigned'};
            app.MapMethodDropDown.ValueChangedFcn = createCallbackFcn(app, @MapMethodDropDownValueChanged, true);
            app.MapMethodDropDown.Enable = 'off';
            app.MapMethodDropDown.Layout.Row = 31;
            app.MapMethodDropDown.Layout.Column = [6 9];
            app.MapMethodDropDown.Value = 'linear';

            % Create DefaultLabelMapMethod
            app.DefaultLabelMapMethod = uilabel(app.GridLayout);
            app.DefaultLabelMapMethod.HorizontalAlignment = 'center';
            app.DefaultLabelMapMethod.Layout.Row = 31;
            app.DefaultLabelMapMethod.Layout.Column = [11 13];
            app.DefaultLabelMapMethod.Text = '-';

            % Create MaxModeDropDownLabel
            app.MaxModeDropDownLabel = uilabel(app.GridLayout);
            app.MaxModeDropDownLabel.HorizontalAlignment = 'center';
            app.MaxModeDropDownLabel.Enable = 'off';
            app.MaxModeDropDownLabel.Layout.Row = 32;
            app.MaxModeDropDownLabel.Layout.Column = [2 5];
            app.MaxModeDropDownLabel.Text = 'Max Mode';

            % Create MaxModeDropDown
            app.MaxModeDropDown = uidropdown(app.GridLayout);
            app.MaxModeDropDown.Items = {'pTrial', 'xTrialxSeg'};
            app.MaxModeDropDown.ValueChangedFcn = createCallbackFcn(app, @MaxModeDropDownValueChanged, true);
            app.MaxModeDropDown.Enable = 'off';
            app.MaxModeDropDown.Layout.Row = 32;
            app.MaxModeDropDown.Layout.Column = [6 9];
            app.MaxModeDropDown.Value = 'pTrial';

            % Create DefaultLabelMaxMode
            app.DefaultLabelMaxMode = uilabel(app.GridLayout);
            app.DefaultLabelMaxMode.HorizontalAlignment = 'center';
            app.DefaultLabelMaxMode.Layout.Row = 32;
            app.DefaultLabelMaxMode.Layout.Column = [11 13];
            app.DefaultLabelMaxMode.Text = '-';

            % Create NoofBinsSpinnerLabel
            app.NoofBinsSpinnerLabel = uilabel(app.GridLayout);
            app.NoofBinsSpinnerLabel.HorizontalAlignment = 'center';
            app.NoofBinsSpinnerLabel.Enable = 'off';
            app.NoofBinsSpinnerLabel.Layout.Row = 33;
            app.NoofBinsSpinnerLabel.Layout.Column = [2 5];
            app.NoofBinsSpinnerLabel.Text = 'No. of Bins';

            % Create NoofBinsSpinner
            app.NoofBinsSpinner = uispinner(app.GridLayout);
            app.NoofBinsSpinner.Limits = [0 Inf];
            app.NoofBinsSpinner.ValueChangedFcn = createCallbackFcn(app, @NoofBinsSpinnerValueChanged, true);
            app.NoofBinsSpinner.Enable = 'off';
            app.NoofBinsSpinner.Layout.Row = 33;
            app.NoofBinsSpinner.Layout.Column = [6 9];

            % Create DefaultLabelNoOfBins
            app.DefaultLabelNoOfBins = uilabel(app.GridLayout);
            app.DefaultLabelNoOfBins.HorizontalAlignment = 'center';
            app.DefaultLabelNoOfBins.Layout.Row = 33;
            app.DefaultLabelNoOfBins.Layout.Column = [11 13];
            app.DefaultLabelNoOfBins.Text = '-';

            % Create XTDCDataFieldButtonGroup
            app.XTDCDataFieldButtonGroup = uibuttongroup(app.GridLayout);
            app.XTDCDataFieldButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @XTDCDataFieldButtonGroupSelectionChanged, true);
            app.XTDCDataFieldButtonGroup.Enable = 'off';
            app.XTDCDataFieldButtonGroup.Title = 'XTDC Data Field';
            app.XTDCDataFieldButtonGroup.Layout.Row = [34 37];
            app.XTDCDataFieldButtonGroup.Layout.Column = [18 21];

            % Create XTDCRawButton
            app.XTDCRawButton = uitogglebutton(app.XTDCDataFieldButtonGroup);
            app.XTDCRawButton.Enable = 'off';
            app.XTDCRawButton.Text = 'Raw';
            app.XTDCRawButton.Position = [1 58 100 22];
            app.XTDCRawButton.Value = true;

            % Create XTDCFilteredButton
            app.XTDCFilteredButton = uitogglebutton(app.XTDCDataFieldButtonGroup);
            app.XTDCFilteredButton.Enable = 'off';
            app.XTDCFilteredButton.Text = 'Filtered';
            app.XTDCFilteredButton.Position = [5 24 100 22];

            % Create XTDCPlotHistograms
            app.XTDCPlotHistograms = uibutton(app.GridLayout, 'push');
            app.XTDCPlotHistograms.ButtonPushedFcn = createCallbackFcn(app, @EMGPlotButtonPushed, true);
            app.XTDCPlotHistograms.Enable = 'off';
            app.XTDCPlotHistograms.Layout.Row = 38;
            app.XTDCPlotHistograms.Layout.Column = [17 22];
            app.XTDCPlotHistograms.Text = 'EMG Button';

            % Create HTMLLineBreak2
            app.HTMLLineBreak2 = uihtml(app.GridLayout);
            app.HTMLLineBreak2.HTMLSource = '<hr>';
            app.HTMLLineBreak2.Layout.Row = 40;
            app.HTMLLineBreak2.Layout.Column = [1 39];

            % Create SDOMultiMatLabel
            app.SDOMultiMatLabel = uilabel(app.GridLayout);
            app.SDOMultiMatLabel.HorizontalAlignment = 'center';
            app.SDOMultiMatLabel.FontSize = 18;
            app.SDOMultiMatLabel.FontWeight = 'bold';
            app.SDOMultiMatLabel.Layout.Row = 41;
            app.SDOMultiMatLabel.Layout.Column = [11 31];
            app.SDOMultiMatLabel.Text = 'SDOMultiMat';

            % Create PX0PX1Panel
            app.PX0PX1Panel = uipanel(app.GridLayout);
            app.PX0PX1Panel.Enable = 'off';
            app.PX0PX1Panel.Title = 'PX0PX1';
            app.PX0PX1Panel.Layout.Row = [42 45];
            app.PX0PX1Panel.Layout.Column = [2 13];

            % Create EMGChannelsLabel
            app.EMGChannelsLabel = uilabel(app.GridLayout);
            app.EMGChannelsLabel.HorizontalAlignment = 'center';
            app.EMGChannelsLabel.Enable = 'off';
            app.EMGChannelsLabel.Layout.Row = [45 47];
            app.EMGChannelsLabel.Layout.Column = [17 19];
            app.EMGChannelsLabel.Text = {'EMG '; 'Channels'};

            % Create EMGChannelsBeforeSMMListBox
            app.EMGChannelsBeforeSMMListBox = uilistbox(app.GridLayout);
            app.EMGChannelsBeforeSMMListBox.Items = {};
            app.EMGChannelsBeforeSMMListBox.Multiselect = 'on';
            app.EMGChannelsBeforeSMMListBox.Enable = 'off';
            app.EMGChannelsBeforeSMMListBox.Layout.Row = [45 47];
            app.EMGChannelsBeforeSMMListBox.Layout.Column = [20 24];
            app.EMGChannelsBeforeSMMListBox.Value = {};

            % Create SMMLabel
            app.SMMLabel = uilabel(app.GridLayout);
            app.SMMLabel.HorizontalAlignment = 'center';
            app.SMMLabel.Enable = 'off';
            app.SMMLabel.Layout.Row = 46;
            app.SMMLabel.Layout.Column = [2 5];
            app.SMMLabel.Text = 'SMM';

            % Create DefaultLabelSMM
            app.DefaultLabelSMM = uilabel(app.GridLayout);
            app.DefaultLabelSMM.HorizontalAlignment = 'center';
            app.DefaultLabelSMM.Enable = 'off';
            app.DefaultLabelSMM.Layout.Row = 46;
            app.DefaultLabelSMM.Layout.Column = [11 13];
            app.DefaultLabelSMM.Text = 'Default';

            % Create PX0DuraMsEditFieldLabel
            app.PX0DuraMsEditFieldLabel = uilabel(app.GridLayout);
            app.PX0DuraMsEditFieldLabel.HorizontalAlignment = 'center';
            app.PX0DuraMsEditFieldLabel.Enable = 'off';
            app.PX0DuraMsEditFieldLabel.Layout.Row = 47;
            app.PX0DuraMsEditFieldLabel.Layout.Column = [2 5];
            app.PX0DuraMsEditFieldLabel.Text = 'PX0 DuraMs';

            % Create PX0DuraMsEditField
            app.PX0DuraMsEditField = uieditfield(app.GridLayout, 'numeric');
            app.PX0DuraMsEditField.Limits = [-Inf 0];
            app.PX0DuraMsEditField.ValueChangedFcn = createCallbackFcn(app, @PX0DuraMsEditFieldValueChanged, true);
            app.PX0DuraMsEditField.Enable = 'off';
            app.PX0DuraMsEditField.Layout.Row = 47;
            app.PX0DuraMsEditField.Layout.Column = [6 9];

            % Create DefaultLabelPX0
            app.DefaultLabelPX0 = uilabel(app.GridLayout);
            app.DefaultLabelPX0.HorizontalAlignment = 'center';
            app.DefaultLabelPX0.Enable = 'off';
            app.DefaultLabelPX0.Layout.Row = 47;
            app.DefaultLabelPX0.Layout.Column = [11 13];
            app.DefaultLabelPX0.Text = '-';

            % Create XTChannelsDropDownLabel
            app.XTChannelsDropDownLabel = uilabel(app.GridLayout);
            app.XTChannelsDropDownLabel.HorizontalAlignment = 'center';
            app.XTChannelsDropDownLabel.Enable = 'off';
            app.XTChannelsDropDownLabel.Layout.Row = 47;
            app.XTChannelsDropDownLabel.Layout.Column = [30 33];
            app.XTChannelsDropDownLabel.Text = 'XT Channels';

            % Create XTChannelsDropDown
            app.XTChannelsDropDown = uidropdown(app.GridLayout);
            app.XTChannelsDropDown.Items = {''};
            app.XTChannelsDropDown.Enable = 'off';
            app.XTChannelsDropDown.Layout.Row = 47;
            app.XTChannelsDropDown.Layout.Column = [34 37];
            app.XTChannelsDropDown.Value = '';

            % Create PX1DuraMsEditFieldLabel
            app.PX1DuraMsEditFieldLabel = uilabel(app.GridLayout);
            app.PX1DuraMsEditFieldLabel.HorizontalAlignment = 'center';
            app.PX1DuraMsEditFieldLabel.Enable = 'off';
            app.PX1DuraMsEditFieldLabel.Layout.Row = 48;
            app.PX1DuraMsEditFieldLabel.Layout.Column = [2 5];
            app.PX1DuraMsEditFieldLabel.Text = 'PX1 DuraMs';

            % Create PX1DuraMsEditField
            app.PX1DuraMsEditField = uieditfield(app.GridLayout, 'numeric');
            app.PX1DuraMsEditField.Limits = [0 Inf];
            app.PX1DuraMsEditField.ValueChangedFcn = createCallbackFcn(app, @PX1DuraMsEditFieldValueChanged, true);
            app.PX1DuraMsEditField.Enable = 'off';
            app.PX1DuraMsEditField.Layout.Row = 48;
            app.PX1DuraMsEditField.Layout.Column = [6 9];

            % Create DefaultLabelPX1
            app.DefaultLabelPX1 = uilabel(app.GridLayout);
            app.DefaultLabelPX1.HorizontalAlignment = 'center';
            app.DefaultLabelPX1.Enable = 'off';
            app.DefaultLabelPX1.Layout.Row = 48;
            app.DefaultLabelPX1.Layout.Column = [11 13];
            app.DefaultLabelPX1.Text = '-';

            % Create PPChannelsLabel
            app.PPChannelsLabel = uilabel(app.GridLayout);
            app.PPChannelsLabel.HorizontalAlignment = 'center';
            app.PPChannelsLabel.Enable = 'off';
            app.PPChannelsLabel.Layout.Row = [48 50];
            app.PPChannelsLabel.Layout.Column = [17 19];
            app.PPChannelsLabel.Text = {'PP '; 'Channels'};

            % Create PPChannelsBeforeSMMListBox
            app.PPChannelsBeforeSMMListBox = uilistbox(app.GridLayout);
            app.PPChannelsBeforeSMMListBox.Items = {};
            app.PPChannelsBeforeSMMListBox.Multiselect = 'on';
            app.PPChannelsBeforeSMMListBox.Enable = 'off';
            app.PPChannelsBeforeSMMListBox.Layout.Row = [48 50];
            app.PPChannelsBeforeSMMListBox.Layout.Column = [20 24];
            app.PPChannelsBeforeSMMListBox.Value = {};

            % Create PPChannelsDropDownLabel
            app.PPChannelsDropDownLabel = uilabel(app.GridLayout);
            app.PPChannelsDropDownLabel.HorizontalAlignment = 'center';
            app.PPChannelsDropDownLabel.Enable = 'off';
            app.PPChannelsDropDownLabel.Layout.Row = 48;
            app.PPChannelsDropDownLabel.Layout.Column = [30 33];
            app.PPChannelsDropDownLabel.Text = 'PP Channels';

            % Create PPChannelsDropDown
            app.PPChannelsDropDown = uidropdown(app.GridLayout);
            app.PPChannelsDropDown.Items = {};
            app.PPChannelsDropDown.Enable = 'off';
            app.PPChannelsDropDown.Layout.Row = 48;
            app.PPChannelsDropDown.Layout.Column = [34 37];
            app.PPChannelsDropDown.Value = {};

            % Create ZDelayEditFieldLabel
            app.ZDelayEditFieldLabel = uilabel(app.GridLayout);
            app.ZDelayEditFieldLabel.HorizontalAlignment = 'center';
            app.ZDelayEditFieldLabel.Enable = 'off';
            app.ZDelayEditFieldLabel.Layout.Row = 49;
            app.ZDelayEditFieldLabel.Layout.Column = [2 5];
            app.ZDelayEditFieldLabel.Text = 'Z Delay';

            % Create ZDelayEditField
            app.ZDelayEditField = uieditfield(app.GridLayout, 'numeric');
            app.ZDelayEditField.Limits = [0 Inf];
            app.ZDelayEditField.ValueChangedFcn = createCallbackFcn(app, @ZDelayEditFieldValueChanged, true);
            app.ZDelayEditField.Enable = 'off';
            app.ZDelayEditField.Layout.Row = 49;
            app.ZDelayEditField.Layout.Column = [6 9];

            % Create DefaultLabelZDelay
            app.DefaultLabelZDelay = uilabel(app.GridLayout);
            app.DefaultLabelZDelay.HorizontalAlignment = 'center';
            app.DefaultLabelZDelay.Enable = 'off';
            app.DefaultLabelZDelay.Layout.Row = 49;
            app.DefaultLabelZDelay.Layout.Column = [11 13];
            app.DefaultLabelZDelay.Text = '-';

            % Create SMMPlotButton
            app.SMMPlotButton = uibutton(app.GridLayout, 'push');
            app.SMMPlotButton.ButtonPushedFcn = createCallbackFcn(app, @SMMPlotButtonPushed, true);
            app.SMMPlotButton.Enable = 'off';
            app.SMMPlotButton.Layout.Row = 49;
            app.SMMPlotButton.Layout.Column = [31 36];
            app.SMMPlotButton.Text = 'Plot';

            % Create NShiftEditFieldLabel
            app.NShiftEditFieldLabel = uilabel(app.GridLayout);
            app.NShiftEditFieldLabel.HorizontalAlignment = 'center';
            app.NShiftEditFieldLabel.Enable = 'off';
            app.NShiftEditFieldLabel.Layout.Row = 50;
            app.NShiftEditFieldLabel.Layout.Column = [2 5];
            app.NShiftEditFieldLabel.Text = 'N Shift';

            % Create NShiftEditField
            app.NShiftEditField = uieditfield(app.GridLayout, 'numeric');
            app.NShiftEditField.Limits = [0 Inf];
            app.NShiftEditField.ValueChangedFcn = createCallbackFcn(app, @NShiftEditFieldValueChanged, true);
            app.NShiftEditField.Enable = 'off';
            app.NShiftEditField.Layout.Row = 50;
            app.NShiftEditField.Layout.Column = [6 9];

            % Create DefaultLabelNShift
            app.DefaultLabelNShift = uilabel(app.GridLayout);
            app.DefaultLabelNShift.HorizontalAlignment = 'center';
            app.DefaultLabelNShift.Enable = 'off';
            app.DefaultLabelNShift.Layout.Row = 50;
            app.DefaultLabelNShift.Layout.Column = [11 13];
            app.DefaultLabelNShift.Text = '-';

            % Create FilterWidthEditFieldLabel
            app.FilterWidthEditFieldLabel = uilabel(app.GridLayout);
            app.FilterWidthEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterWidthEditFieldLabel.Enable = 'off';
            app.FilterWidthEditFieldLabel.Layout.Row = 51;
            app.FilterWidthEditFieldLabel.Layout.Column = [2 5];
            app.FilterWidthEditFieldLabel.Text = 'Filter Width';

            % Create FilterWidthEditField
            app.FilterWidthEditField = uieditfield(app.GridLayout, 'numeric');
            app.FilterWidthEditField.Limits = [0 Inf];
            app.FilterWidthEditField.ValueChangedFcn = createCallbackFcn(app, @FilterWidthEditFieldValueChanged, true);
            app.FilterWidthEditField.Enable = 'off';
            app.FilterWidthEditField.Layout.Row = 51;
            app.FilterWidthEditField.Layout.Column = [6 9];

            % Create DefaultLabelFilterWidth
            app.DefaultLabelFilterWidth = uilabel(app.GridLayout);
            app.DefaultLabelFilterWidth.HorizontalAlignment = 'center';
            app.DefaultLabelFilterWidth.Enable = 'off';
            app.DefaultLabelFilterWidth.Layout.Row = 51;
            app.DefaultLabelFilterWidth.Layout.Column = [11 13];
            app.DefaultLabelFilterWidth.Text = '-';

            % Create CreateSMMSelectedButton
            app.CreateSMMSelectedButton = uibutton(app.GridLayout, 'push');
            app.CreateSMMSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @CreateSMMSelectedButtonPushed, true);
            app.CreateSMMSelectedButton.Enable = 'off';
            app.CreateSMMSelectedButton.Layout.Row = 51;
            app.CreateSMMSelectedButton.Layout.Column = [18 23];
            app.CreateSMMSelectedButton.Text = 'CreateSMM Selected';

            % Create FilterStdEditFieldLabel
            app.FilterStdEditFieldLabel = uilabel(app.GridLayout);
            app.FilterStdEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterStdEditFieldLabel.Enable = 'off';
            app.FilterStdEditFieldLabel.Layout.Row = 52;
            app.FilterStdEditFieldLabel.Layout.Column = [2 5];
            app.FilterStdEditFieldLabel.Text = 'Filter Std';

            % Create FilterStdEditField
            app.FilterStdEditField = uieditfield(app.GridLayout, 'numeric');
            app.FilterStdEditField.Limits = [0 Inf];
            app.FilterStdEditField.ValueChangedFcn = createCallbackFcn(app, @FilterStdEditFieldValueChanged, true);
            app.FilterStdEditField.Enable = 'off';
            app.FilterStdEditField.Layout.Row = 52;
            app.FilterStdEditField.Layout.Column = [6 9];

            % Create DefaultLabelFilterStd
            app.DefaultLabelFilterStd = uilabel(app.GridLayout);
            app.DefaultLabelFilterStd.HorizontalAlignment = 'center';
            app.DefaultLabelFilterStd.Enable = 'off';
            app.DefaultLabelFilterStd.Layout.Row = 52;
            app.DefaultLabelFilterStd.Layout.Column = [11 13];
            app.DefaultLabelFilterStd.Text = '-';

            % Create CreateSMMAllButton
            app.CreateSMMAllButton = uibutton(app.GridLayout, 'push');
            app.CreateSMMAllButton.ButtonPushedFcn = createCallbackFcn(app, @CreateSMMAllButtonPushed, true);
            app.CreateSMMAllButton.Enable = 'off';
            app.CreateSMMAllButton.Layout.Row = 52;
            app.CreateSMMAllButton.Layout.Column = [18 23];
            app.CreateSMMAllButton.Text = 'CreateSMM All';

            % Create NoofEventsEditFieldLabel
            app.NoofEventsEditFieldLabel = uilabel(app.GridLayout);
            app.NoofEventsEditFieldLabel.HorizontalAlignment = 'center';
            app.NoofEventsEditFieldLabel.Enable = 'off';
            app.NoofEventsEditFieldLabel.Layout.Row = 53;
            app.NoofEventsEditFieldLabel.Layout.Column = [2 5];
            app.NoofEventsEditFieldLabel.Text = 'No of Events';

            % Create NoofEventsEditField
            app.NoofEventsEditField = uieditfield(app.GridLayout, 'numeric');
            app.NoofEventsEditField.Limits = [0 Inf];
            app.NoofEventsEditField.Editable = 'off';
            app.NoofEventsEditField.Enable = 'off';
            app.NoofEventsEditField.Layout.Row = 53;
            app.NoofEventsEditField.Layout.Column = [6 9];

            % Create NoofEventsDropDown
            app.NoofEventsDropDown = uidropdown(app.GridLayout);
            app.NoofEventsDropDown.Items = {};
            app.NoofEventsDropDown.ValueChangedFcn = createCallbackFcn(app, @NoofEventsDropDownValueChanged, true);
            app.NoofEventsDropDown.Enable = 'off';
            app.NoofEventsDropDown.Layout.Row = 53;
            app.NoofEventsDropDown.Layout.Column = [11 13];
            app.NoofEventsDropDown.Value = {};

            % Create MatrixPanel
            app.MatrixPanel = uipanel(app.GridLayout);
            app.MatrixPanel.Layout.Row = 54;
            app.MatrixPanel.Layout.Column = [4 18];

            % Create StirpdPanel
            app.StirpdPanel = uipanel(app.GridLayout);
            app.StirpdPanel.Layout.Row = 54;
            app.StirpdPanel.Layout.Column = [22 36];

            % Create DiffusionPanel
            app.DiffusionPanel = uipanel(app.GridLayout);
            app.DiffusionPanel.Layout.Row = 55;
            app.DiffusionPanel.Layout.Column = [10 30];

            % Create XTrialXSegWarningLabel
            app.XTrialXSegWarningLabel = uilabel(app.GridLayout);
            app.XTrialXSegWarningLabel.HorizontalAlignment = 'center';
            app.XTrialXSegWarningLabel.FontSize = 9;
            app.XTrialXSegWarningLabel.FontColor = [1 0 0];
            app.XTrialXSegWarningLabel.Enable = 'off';
            app.XTrialXSegWarningLabel.Visible = 'off';
            app.XTrialXSegWarningLabel.Layout.Row = 34;
            app.XTrialXSegWarningLabel.Layout.Column = [2 13];
            app.XTrialXSegWarningLabel.Text = 'xTrailxSeg: Changing max/min will result in changing values for all the trials ';

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

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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